#!/usr/bin/env python3
"""
Script di migrazione automatica da Riverpod 2.x a 3.x
Converte StateNotifierProvider e StateProvider al nuovo pattern con code generation
"""

import os
import re
from pathlib import Path
from typing import List, Tuple

def add_riverpod_imports_and_part(file_path: Path, content: str) -> str:
    """Aggiunge gli import necessari e la direttiva part"""
    
    # Verifica se import_riverpod è già presente
    if "import 'package:riverpod_annotation/riverpod_annotation.dart';" not in content:
        # Trova la posizione dopo gli import esistenti
        import_pattern = r"(import\s+['\"]package:.*?['\"];?\s*\n)+"
        match = re.search(import_pattern, content)
        
        if match:
            last_import_end = match.end()
            new_imports = "\nimport 'package:riverpod_annotation/riverpod_annotation.dart';\n"
            content = content[:last_import_end] + new_imports + content[last_import_end:]
    
    # Aggiungi part directive
    file_name = file_path.stem
    part_directive = f"\npart '{file_name}.g.dart';\n"
    
    if part_directive.strip() not in content:
        # Aggiungi dopo gli import
        import_pattern = r"(import\s+['\"].*?['\"];?\s*\n)+"
        match = re.search(import_pattern, content)
        if match:
            last_import_end = match.end()
            content = content[:last_import_end] + part_directive + content[last_import_end:]
    
    return content

def migrate_state_notifier_provider(content: str) -> str:
    """Converte StateNotifierProvider in NotifierProvider con @riverpod"""
    
    # Pattern per trovare StateNotifierProvider
    pattern = r'final\s+(\w+)\s*=\s*StateNotifierProvider<(\w+),\s*(\w+)>\(\(ref\)\s*{\s*return\s+(\w+)\(\);?\s*}\);'
    
    def replace_provider(match):
        provider_name = match.group(1)
        notifier_class = match.group(2)
        state_type = match.group(3)
        constructor = match.group(4)
        
        # Genera il nuovo codice con @riverpod
        return f"// Migrated to Riverpod 3.x - see {notifier_class} class below\n// Old: {match.group(0)}"
    
    content = re.sub(pattern, replace_provider, content)
    return content

def migrate_state_notifier_class(content: str) -> str:
    """Converte class extends StateNotifier in Notifier con @riverpod"""
    
    # Pattern per class che estende StateNotifier
    pattern = r'class\s+(\w+)\s+extends\s+StateNotifier<(\w+)>\s*{'
    
    def replace_class(match):
        class_name = match.group(1)
        state_type = match.group(2)
        
        # Converti in Notifier with annotation
        return f'@riverpod\nclass {class_name} extends _${class_name} {{'
    
    content = re.sub(pattern, replace_class, content)
    
    # Replace state = ... with methods
    # Questo è più complesso e potrebbe richiedere revisione manuale
    
    return content

def migrate_state_provider(content: str) -> str:
    """Converte StateProvider in NotifierProvider"""
    
    pattern = r'final\s+(\w+)\s*=\s*StateProvider<(\w+)>\(\(ref\)\s*=>\s*(.+?)\);'
    
    def replace_provider(match):
        provider_name = match.group(1)
        state_type = match.group(2)
        initial_value = match.group(3)
        
        # Generate notifier class name
        class_name = ''.join(word.capitalize() for word in provider_name.replace('Provider', '').split('_'))
        
        return f'''// Migrated StateProvider to Notifier
@riverpod
class {class_name} extends _${class_name} {{
  @override
  {state_type} build() => {initial_value};
  
  void update({state_type} value) => state = value;
}}'''
    
    content = re.sub(pattern, replace_provider, content, flags=re.MULTILINE)
    return content

def remove_super_state_calls(content: str) -> str:
    """Rimuove le chiamate super(...) nei costruttori StateNotifier"""
    
    # Pattern per costruttori con super(initialState)
    pattern = r'(\w+)\(\)\s*:\s*super\([^)]+\);'
    
    def replace_constructor(match):
        constructor_name = match.group(1)
        return f'''@override
  build() => // TODO: Return initial state here;'''
    
    content = re.sub(pattern, replace_constructor, content)
    return content

def migrate_file(file_path: Path) -> Tuple[bool, str]:
    """Migra un singolo file da Riverpod 2.x a 3.x"""
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Verifica se il file contiene provider da migrare
        if 'StateNotifierProvider' not in content and 'StateProvider' not in content:
            return False, "No Riverpod providers found"
        
        # Applica le migrazioni
        content = add_riverpod_imports_and_part(file_path, content)
        content = migrate_state_notifier_provider(content)
        content = migrate_state_provider(content)
        content = migrate_state_notifier_class(content)
        content = remove_super_state_calls(content)
        
        # Salva se ci sono modifiche
        if content != original_content:
            # Crea backup
            backup_path = file_path.with_suffix('.dart.bak')
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(original_content)
            
            # Salva il file migrato
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            return True, f"Migrated successfully (backup: {backup_path.name})"
        else:
            return False, "No changes needed"
            
    except Exception as e:
        return False, f"Error: {str(e)}"

def find_provider_files(root_dir: Path) -> List[Path]:
    """Trova tutti i file Dart che contengono provider"""
    
    provider_files = []
    
    for dart_file in root_dir.rglob('*.dart'):
        # Skip generated files
        if dart_file.suffix == '.g.dart' or dart_file.suffix == '.freezed.dart':
            continue
            
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
                if 'StateNotifierProvider' in content or 'StateProvider' in content or 'FutureProviderFamily' in content:
                    provider_files.append(dart_file)
        except:
            pass
    
    return provider_files

def main():
    """Main migration script"""
    
    # Ottieni la directory root del progetto
    script_dir = Path(__file__).parent
    lib_dir = script_dir / 'lib'
    
    if not lib_dir.exists():
        print(f"❌ Directory lib non trovata: {lib_dir}")
        return
    
    print("🔍 Ricerca file con provider Riverpod...")
    provider_files = find_provider_files(lib_dir)
    
    print(f"\n📁 Trovati {len(provider_files)} file da migrare:\n")
    
    for i, file_path in enumerate(provider_files, 1):
        rel_path = file_path.relative_to(lib_dir)
        print(f"  {i}. {rel_path}")
    
    print("\n⚠️  ATTENZIONE: Questa operazione modificherà i file e creerà backup (.dart.bak)")
    response = input("\n▶ Procedere con la migrazione? (y/N): ")
    
    if response.lower() != 'y':
        print("❌ Migrazione annullata")
        return
    
    print("\n🚀 Inizio migrazione...\n")
    
    migrated_count = 0
    error_count = 0
    
    for file_path in provider_files:
        rel_path = file_path.relative_to(lib_dir)
        success, message = migrate_file(file_path)
        
        if success:
            print(f"✅ {rel_path}: {message}")
            migrated_count += 1
        else:
            if "Error:" in message:
                print(f"❌ {rel_path}: {message}")
                error_count += 1
            else:
                print(f"⏭️  {rel_path}: {message}")
    
    print(f"\n📊 Riepilogo:")
    print(f"  ✅ File migrati: {migrated_count}")
    print(f"  ❌ Errori: {error_count}")
    print(f"  📝 File totali: {len(provider_files)}")
    
    if migrated_count > 0:
        print(f"\n⚠️  NOTA: La migrazione automatica potrebbe richiedere correzioni manuali.")
        print(f"  Prossimi passi:")
        print(f"  1. Rivedi i file migrati")
        print(f"  2. Esegui: flutter pub run build_runner build --delete-conflicting-outputs")
        print(f"  3. Correggi eventuali errori rimanenti")

if __name__ == '__main__':
    main()
