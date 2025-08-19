import React, { useState, useEffect } from 'react';
import { Search, Plus, Edit3, Trash2, Tag, Calendar, Moon, Sun, Briefcase, User, Home, Settings, FileText, Wifi, WifiOff, Cloud } from 'lucide-react';

const RocketNotesWeb = () => {
  const [notes, setNotes] = useState([]);
  const [currentMode, setCurrentMode] = useState('work');
  const [darkMode, setDarkMode] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [activeScreen, setActiveScreen] = useState('home');
  const [editingNote, setEditingNote] = useState(null);
  const [newNote, setNewNote] = useState({ title: '', content: '', tags: '' });
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [isSyncing, setIsSyncing] = useState(false);
  const [lastSyncTime, setLastSyncTime] = useState(null);
  const [userId] = useState('user_' + Math.random().toString(36).substr(2, 9)); // Simulate user ID

  // Mock API endpoints - replace with your actual backend
  const API_BASE = 'https://api.rocketnotes.com'; // Replace with your backend URL
  
  // Simulated API calls for demonstration
  const api = {
    async get(endpoint) {
      // Simulate network delay
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Return mock data for demo - replace with actual fetch calls
      if (endpoint === '/notes') {
        const mockData = localStorage.getItem('rocketnotes_sync_data');
        return mockData ? JSON.parse(mockData) : [];
      }
      return [];
    },
    
    async post(endpoint, data) {
      await new Promise(resolve => setTimeout(resolve, 300));
      
      if (endpoint === '/notes') {
        const currentData = localStorage.getItem('rocketnotes_sync_data');
        const notes = currentData ? JSON.parse(currentData) : [];
        const newNote = { ...data, id: Date.now().toString(), createdAt: new Date(), updatedAt: new Date() };
        const updatedNotes = [newNote, ...notes];
        localStorage.setItem('rocketnotes_sync_data', JSON.stringify(updatedNotes));
        return newNote;
      }
    },
    
    async put(endpoint, data) {
      await new Promise(resolve => setTimeout(resolve, 300));
      
      if (endpoint.startsWith('/notes/')) {
        const currentData = localStorage.getItem('rocketnotes_sync_data');
        const notes = currentData ? JSON.parse(currentData) : [];
        const updatedNotes = notes.map(note => 
          note.id === data.id ? { ...data, updatedAt: new Date() } : note
        );
        localStorage.setItem('rocketnotes_sync_data', JSON.stringify(updatedNotes));
        return data;
      }
    },
    
    async delete(endpoint) {
      await new Promise(resolve => setTimeout(resolve, 300));
      
      if (endpoint.startsWith('/notes/')) {
        const noteId = endpoint.split('/').pop();
        const currentData = localStorage.getItem('rocketnotes_sync_data');
        const notes = currentData ? JSON.parse(currentData) : [];
        const filteredNotes = notes.filter(note => note.id !== noteId);
        localStorage.setItem('rocketnotes_sync_data', JSON.stringify(filteredNotes));
        return { success: true };
      }
    }
  };

  // Initialize and sync
  useEffect(() => {
    initializeApp();
    setupNetworkListeners();
    setupSyncInterval();
    
    return () => {
      clearInterval(syncInterval);
    };
  }, []);

  const initializeApp = async () => {
    // Load local settings
    const savedTheme = localStorage.getItem('darkMode');
    const savedMode = localStorage.getItem('currentMode');
    
    if (savedTheme) setDarkMode(JSON.parse(savedTheme));
    if (savedMode) setCurrentMode(savedMode);

    // Initial sync
    await syncWithServer();
  };

  const setupNetworkListeners = () => {
    const handleOnline = () => {
      setIsOnline(true);
      syncWithServer(); // Auto-sync when back online
    };
    
    const handleOffline = () => setIsOnline(false);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
  };

  let syncInterval;
  const setupSyncInterval = () => {
    // Sync every 30 seconds when online
    syncInterval = setInterval(() => {
      if (isOnline) {
        syncWithServer();
      }
    }, 30000);
  };

  const syncWithServer = async () => {
    if (!isOnline) return;
    
    setIsSyncing(true);
    try {
      // Fetch latest notes from server
      const serverNotes = await api.get('/notes');
      
      // Merge with local notes (conflict resolution)
      const localNotes = JSON.parse(localStorage.getItem('rocketnotes_local_notes') || '[]');
      const mergedNotes = mergeNotes(localNotes, serverNotes);
      
      setNotes(mergedNotes);
      setLastSyncTime(new Date());
      
      // Clear local-only storage after successful sync
      localStorage.removeItem('rocketnotes_local_notes');
      
    } catch (error) {
      console.error('Sync failed:', error);
      // Load local notes if sync fails
      const localNotes = JSON.parse(localStorage.getItem('rocketnotes_local_notes') || '[]');
      setNotes(localNotes);
    } finally {
      setIsSyncing(false);
    }
  };

  const mergeNotes = (localNotes, serverNotes) => {
    const merged = new Map();
    
    // Add server notes
    serverNotes.forEach(note => {
      merged.set(note.id, note);
    });
    
    // Add local notes, preferring newer versions
    localNotes.forEach(localNote => {
      const serverNote = merged.get(localNote.id);
      if (!serverNote || new Date(localNote.updatedAt) > new Date(serverNote.updatedAt)) {
        merged.set(localNote.id, localNote);
      }
    });
    
    return Array.from(merged.values()).sort((a, b) => 
      new Date(b.updatedAt) - new Date(a.updatedAt)
    );
  };

  const saveNoteLocally = (note) => {
    const localNotes = JSON.parse(localStorage.getItem('rocketnotes_local_notes') || '[]');
    const updatedNotes = localNotes.filter(n => n.id !== note.id);
    updatedNotes.unshift(note);
    localStorage.setItem('rocketnotes_local_notes', JSON.stringify(updatedNotes));
    setNotes(prevNotes => {
      const filtered = prevNotes.filter(n => n.id !== note.id);
      return [note, ...filtered];
    });
  };

  const handleCreateNote = async () => {
    if (newNote.title.trim() || newNote.content.trim()) {
      const note = {
        id: Date.now().toString(),
        title: newNote.title || 'Untitled Note',
        content: newNote.content,
        mode: currentMode,
        createdAt: new Date(),
        updatedAt: new Date(),
        tags: newNote.tags.split(',').map(tag => tag.trim()).filter(tag => tag),
        userId: userId,
        aiSummary: `Note about ${newNote.title || 'various topics'}.`
      };
      
      // Save locally first
      saveNoteLocally(note);
      setNewNote({ title: '', content: '', tags: '' });
      setActiveScreen('notes');
      
      // Sync to server if online
      if (isOnline) {
        try {
          await api.post('/notes', note);
          await syncWithServer(); // Refresh from server
        } catch (error) {
          console.error('Failed to sync new note:', error);
        }
      }
    }
  };

  const handleUpdateNote = async () => {
    if (editingNote && (editingNote.title.trim() || editingNote.content.trim())) {
      const updatedNote = {
        ...editingNote,
        updatedAt: new Date(),
        tags: editingNote.tags.split(',').map(tag => tag.trim()).filter(tag => tag)
      };
      
      // Save locally first
      saveNoteLocally(updatedNote);
      setEditingNote(null);
      setActiveScreen('notes');
      
      // Sync to server if online
      if (isOnline) {
        try {
          await api.put(`/notes/${updatedNote.id}`, updatedNote);
          await syncWithServer(); // Refresh from server
        } catch (error) {
          console.error('Failed to sync updated note:', error);
        }
      }
    }
  };

  const handleDeleteNote = async (id) => {
    if (window.confirm('Are you sure you want to delete this note?')) {
      // Remove locally first
      setNotes(prevNotes => prevNotes.filter(note => note.id !== id));
      
      // Remove from local storage
      const localNotes = JSON.parse(localStorage.getItem('rocketnotes_local_notes') || '[]');
      const filteredLocal = localNotes.filter(note => note.id !== id);
      localStorage.setItem('rocketnotes_local_notes', JSON.stringify(filteredLocal));
      
      // Sync to server if online
      if (isOnline) {
        try {
          await api.delete(`/notes/${id}`);
          await syncWithServer(); // Refresh from server
        } catch (error) {
          console.error('Failed to sync note deletion:', error);
        }
      }
    }
  };

  // Save settings changes
  useEffect(() => {
    localStorage.setItem('darkMode', JSON.stringify(darkMode));
  }, [darkMode]);

  useEffect(() => {
    localStorage.setItem('currentMode', currentMode);
  }, [currentMode]);

  const filteredNotes = notes.filter(note => {
    const matchesMode = note.mode === currentMode;
    const matchesSearch = searchTerm === '' || 
      note.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      note.content.toLowerCase().includes(searchTerm.toLowerCase()) ||
      note.tags.some(tag => tag.toLowerCase().includes(searchTerm.toLowerCase()));
    return matchesMode && matchesSearch;
  });

  const formatDate = (date) => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(new Date(date));
  };

  const SyncStatus = () => (
    <div className="flex items-center space-x-2 text-sm">
      <div className={`flex items-center space-x-1 ${isOnline ? 'text-green-600' : 'text-red-600'}`}>
        {isOnline ? <Wifi size={16} /> : <WifiOff size={16} />}
        <span>{isOnline ? 'Online' : 'Offline'}</span>
      </div>
      
      {isSyncing && (
        <div className="flex items-center space-x-1 text-blue-600">
          <div className="w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
          <span>Syncing...</span>
        </div>
      )}
      
      {lastSyncTime && !isSyncing && (
        <div className="flex items-center space-x-1 text-gray-500">
          <Cloud size={16} />
          <span>Last sync: {formatDate(lastSyncTime)}</span>
        </div>
      )}
      
      <button
        onClick={syncWithServer}
        disabled={!isOnline || isSyncing}
        className="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-50"
        title="Manual sync"
      >
        <div className={`w-4 h-4 border-2 border-gray-500 border-t-transparent rounded-full ${isSyncing ? 'animate-spin' : ''}`}></div>
      </button>
    </div>
  );

  const HomeScreen = () => (
    <div className="space-y-6">
      <div className="text-center py-12">
        <div className="text-6xl mb-4">🚀</div>
        <h1 className="text-4xl font-bold mb-2 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
          RocketNotes AI
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          Your intelligent note-taking companion - Now with sync!
        </p>
        <div className="mt-4">
          <SyncStatus />
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        <div 
          className={`p-6 rounded-2xl cursor-pointer transition-all transform hover:scale-105 ${
            currentMode === 'work' 
              ? 'bg-blue-500 text-white shadow-lg' 
              : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
          }`}
          onClick={() => setCurrentMode('work')}
        >
          <div className="flex items-center mb-4">
            <Briefcase size={32} className="mr-3" />
            <h3 className="text-xl font-semibold">Work Mode</h3>
          </div>
          <p className="opacity-90">
            Focus on professional notes, meetings, and project ideas
          </p>
          <div className="mt-4 text-sm opacity-75">
            {notes.filter(n => n.mode === 'work').length} notes
          </div>
        </div>

        <div 
          className={`p-6 rounded-2xl cursor-pointer transition-all transform hover:scale-105 ${
            currentMode === 'personal' 
              ? 'bg-green-500 text-white shadow-lg' 
              : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
          }`}
          onClick={() => setCurrentMode('personal')}
        >
          <div className="flex items-center mb-4">
            <User size={32} className="mr-3" />
            <h3 className="text-xl font-semibold">Personal Mode</h3>
          </div>
          <p className="opacity-90">
            Capture personal thoughts, ideas, and memories
          </p>
          <div className="mt-4 text-sm opacity-75">
            {notes.filter(n => n.mode === 'personal').length} notes
          </div>
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-sm">
        <h3 className="text-lg font-semibold mb-4">Recent Notes</h3>
        <div className="space-y-3">
          {notes.slice(0, 3).map(note => (
            <div key={note.id} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
              <div>
                <h4 className="font-medium text-sm">{note.title}</h4>
                <p className="text-xs text-gray-600 dark:text-gray-400">{formatDate(note.updatedAt)}</p>
              </div>
              <div className={`w-3 h-3 rounded-full ${note.mode === 'work' ? 'bg-blue-500' : 'bg-green-500'}`}></div>
            </div>
          ))}
        </div>
      </div>
      
      {!isOnline && (
        <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-700 rounded-xl p-4">
          <div className="flex items-center space-x-2">
            <WifiOff size={20} className="text-yellow-600 dark:text-yellow-400" />
            <div>
              <h4 className="font-semibold text-yellow-800 dark:text-yellow-200">Working Offline</h4>
              <p className="text-sm text-yellow-600 dark:text-yellow-400">
                Your changes are saved locally and will sync when you're back online.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );

  const NotesScreen = () => (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Search notes..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-3 border border-gray-200 dark:border-gray-700 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-800"
          />
        </div>
        <button
          onClick={() => setActiveScreen('create')}
          className="flex items-center justify-center px-6 py-3 bg-blue-500 text-white rounded-xl hover:bg-blue-600 transition-colors"
        >
          <Plus size={20} className="mr-2" />
          New Note
        </button>
      </div>

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">
          {currentMode === 'work' ? 'Work' : 'Personal'} Notes ({filteredNotes.length})
        </h2>
        <SyncStatus />
      </div>

      <div className="grid gap-4">
        {filteredNotes.map(note => (
          <div key={note.id} className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-3">
              <h3 className="font-semibold text-lg">{note.title}</h3>
              <div className="flex space-x-2">
                <button
                  onClick={() => {
                    setEditingNote({...note, tags: note.tags.join(', ')});
                    setActiveScreen('edit');
                  }}
                  className="p-2 text-gray-500 hover:text-blue-500 transition-colors"
                >
                  <Edit3 size={16} />
                </button>
                <button
                  onClick={() => handleDeleteNote(note.id)}
                  className="p-2 text-gray-500 hover:text-red-500 transition-colors"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
            
            <p className="text-gray-600 dark:text-gray-300 mb-3 line-clamp-3">
              {note.content}
            </p>
            
            {note.aiSummary && (
              <div className="bg-blue-50 dark:bg-blue-900/20 p-3 rounded-lg mb-3">
                <p className="text-sm text-blue-800 dark:text-blue-200">
                  <strong>AI Summary:</strong> {note.aiSummary}
                </p>
              </div>
            )}
            
            <div className="flex flex-wrap gap-2 mb-3">
              {note.tags.map(tag => (
                <span key={tag} className="inline-flex items-center px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 text-xs rounded-full">
                  <Tag size={12} className="mr-1" />
                  {tag}
                </span>
              ))}
            </div>
            
            <div className="flex justify-between items-center text-sm text-gray-500 dark:text-gray-400">
              <span className="flex items-center">
                <Calendar size={14} className="mr-1" />
                {formatDate(note.updatedAt)}
              </span>
              <span className={`px-2 py-1 rounded-full text-xs ${
                note.mode === 'work' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' : 
                'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
              }`}>
                {note.mode}
              </span>
            </div>
          </div>
        ))}
        
        {filteredNotes.length === 0 && (
          <div className="text-center py-12 text-gray-500 dark:text-gray-400">
            <FileText size={48} className="mx-auto mb-4 opacity-50" />
            <p>No notes found. Create your first note!</p>
          </div>
        )}
      </div>
    </div>
  );

  const CreateEditScreen = ({ isEditing = false }) => {
    const currentNote = isEditing ? editingNote : newNote;
    const setCurrentNote = isEditing ? setEditingNote : setNewNote;
    const handleSave = isEditing ? handleUpdateNote : handleCreateNote;

    return (
      <div className="max-w-4xl mx-auto">
        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h2 className="text-2xl font-bold">
                {isEditing ? 'Edit Note' : 'Create New Note'}
              </h2>
              <SyncStatus />
            </div>
            <div className="flex space-x-3">
              <button
                onClick={() => setActiveScreen('notes')}
                className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
              >
                {isEditing ? 'Update' : 'Create'}
              </button>
            </div>
          </div>

          <div className="space-y-4">
            <input
              type="text"
              placeholder="Note title..."
              value={currentNote.title}
              onChange={(e) => setCurrentNote({...currentNote, title: e.target.value})}
              className="w-full text-xl font-semibold border-none outline-none bg-transparent placeholder-gray-400"
            />
            
            <textarea
              placeholder="Write your note here..."
              value={currentNote.content}
              onChange={(e) => setCurrentNote({...currentNote, content: e.target.value})}
              rows={15}
              className="w-full border border-gray-200 dark:border-gray-700 rounded-lg p-4 focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none bg-white dark:bg-gray-800"
            />
            
            <input
              type="text"
              placeholder="Tags (comma-separated)..."
              value={currentNote.tags}
              onChange={(e) => setCurrentNote({...currentNote, tags: e.target.value})}
              className="w-full border border-gray-200 dark:border-gray-700 rounded-lg p-3 focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-800"
            />
          </div>
        </div>
      </div>
    );
  };

  const SettingsScreen = () => (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
        <h2 className="text-2xl font-bold mb-6">Settings</h2>
        
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <div>
              <h3 className="font-semibold">Dark Mode</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">Toggle between light and dark themes</p>
            </div>
            <button
              onClick={() => setDarkMode(!darkMode)}
              className={`p-2 rounded-lg transition-colors ${
                darkMode ? 'bg-blue-500 text-white' : 'bg-gray-200 text-gray-700'
              }`}
            >
              {darkMode ? <Moon size={20} /> : <Sun size={20} />}
            </button>
          </div>
          
          <div className="flex justify-between items-center">
            <div>
              <h3 className="font-semibold">Current Mode</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">Switch between work and personal modes</p>
            </div>
            <div className="flex bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
              <button
                onClick={() => setCurrentMode('work')}
                className={`px-4 py-2 rounded-md text-sm transition-colors ${
                  currentMode === 'work' ? 'bg-blue-500 text-white' : 'text-gray-700 dark:text-gray-300'
                }`}
              >
                Work
              </button>
              <button
                onClick={() => setCurrentMode('personal')}
                className={`px-4 py-2 rounded-md text-sm transition-colors ${
                  currentMode === 'personal' ? 'bg-green-500 text-white' : 'text-gray-700 dark:text-gray-300'
                }`}
              >
                Personal
              </button>
            </div>
          </div>
          
          <div className="border-t pt-6">
            <h3 className="font-semibold mb-4">Sync Settings</h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <p className="font-medium">Auto Sync</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Automatically sync when online</p>
                </div>
                <span className="text-green-600 dark:text-green-400">Enabled</span>
              </div>
              <div className="flex justify-between items-center">
                <div>
                  <p className="font-medium">User ID</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Your unique identifier</p>
                </div>
                <code className="text-xs bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">{userId}</code>
              </div>
              <SyncStatus />
            </div>
          </div>
        </div>
      </div>
      
      <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
        <h3 className="font-semibold mb-4">Statistics</h3>
        <div className="grid grid-cols-2 gap-4">
          <div className="text-center p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
            <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
              {notes.filter(n => n.mode === 'work').length}
            </div>
            <div className="text-sm text-blue-600 dark:text-blue-400">Work Notes</div>
          </div>
          <div className="text-center p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
            <div className="text-2xl font-bold text-green-600 dark:text-green-400">
              {notes.filter(n => n.mode === 'personal').length}
            </div>
            <div className="text-sm text-green-600 dark:text-green-400">Personal Notes</div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderScreen = () => {
    switch (activeScreen) {
      case 'home': return <HomeScreen />;
      case 'notes': return <NotesScreen />;
      case 'create': return <CreateEditScreen />;
      case 'edit': return <CreateEditScreen isEditing />;
      case 'settings': return <SettingsScreen />;
      default: return <HomeScreen />;
    }
  };

  return (
    <div className={`min-h-screen transition-colors ${darkMode ? 'dark bg-gray-900' : 'bg-gray-50'}`}>
      <nav className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <span className="text-2xl">🚀</span>
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                RocketNotes Web
              </h1>
              <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                currentMode === 'work' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' : 
                'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
              }`}>
                {currentMode}
              </span>
              <div className={`w-2 h-2 rounded-full ${isOnline ? 'bg-green-500' : 'bg-red-500'}`}></div>
            </div>
            
            <div className="flex items-center space-x-6">
              <button
                onClick={() => setActiveScreen('home')}
                className={`flex items-center px-3 py-2 rounded-lg transition-colors ${
                  activeScreen === 'home' ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-200' : 
                  'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100'
                }`}
              >
                <Home size={18} className="mr-1" />
                Home
              </button>
              
              <button
                onClick={() => setActiveScreen('notes')}
                className={`flex items-center px-3 py-2 rounded-lg transition-colors ${
                  activeScreen === 'notes' ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-200' : 
                  'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100'
                }`}
              >
                <FileText size={18} className="mr-1" />
                Notes
              </button>
              
              <button
                onClick={() => setActiveScreen('settings')}
                className={`flex items-center px-3 py-2 rounded-lg transition-colors ${
                  activeScreen === 'settings' ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-200' : 
                  'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100'
                }`}
              >
                <Settings size={18} className="mr-1" />
                Settings
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {renderScreen()}
      </main>
    </div>
  );
};

export default RocketNotesWeb;
