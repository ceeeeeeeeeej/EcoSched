// Notifications page functionality
import { dbService, realtime } from '../../config/supabase_config.js';

console.log('🔔 Notifications page loaded');

// Notifications storage
let notifications = [];
let filteredNotifications = [];
let sensorSubscription = null;

// Initialize page
document.addEventListener('DOMContentLoaded', function () {
    console.log('🔔 Initializing notifications page...');
    loadNotifications();
    setupRealtimeSubscription();
    setupFilterListeners();
});

// Cleanup subscriptions on page unload
window.addEventListener('beforeunload', () => {
    if (sensorSubscription) {
        sensorSubscription.unsubscribe();
    }
});

// Load notifications from Supabase and merge with localStorage
async function loadNotifications() {
    console.log('🔄 Loading persistent notifications...');

    // 1. Fetch real notifications from Supabase
    // Parallel fetch for personal notifications AND announcements
    const [personalReq, communityReq] = await Promise.all([
        dbService.getGenericNotifications(100),
        dbService.getCommunityNotifications(50)
    ]);

    const { data: dbNotifications, error: dbError } = personalReq;
    const { data: communityNotifs, error: commError } = communityReq;

    if (dbError) console.error('❌ Error fetching notifications:', dbError);
    if (commError) console.error('❌ Error fetching announcements:', commError);

    // 2. Map personal notifications
    const personalMapped = (dbNotifications || []).map(n => ({
        ...n,
        timestamp: n.createdAt || n.timestamp,
        priority: n.priority || 'low',
        source: 'personal'
    }));

    // 3. Map community notifications (announcements)
    // Mark them as "system" type strictly for UI
    const communityMapped = (communityNotifs || []).map(n => ({
        ...n,
        timestamp: n.createdAt,
        type: 'system',
        priority: 'medium', // Announcements are usually important
        source: 'community'
    }));

    // Remove duplicates and merge
    notifications = [...personalMapped, ...communityMapped]
        .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
        .slice(0, 100);

    filteredNotifications = [...notifications];

    renderNotifications();
    updateStats();
}

// Setup real-time subscription for database notifications
function setupRealtimeSubscription() {
    if (!realtime || !realtime.subscribeToGenericNotifications) {
        console.warn('⚠️ Realtime notification subscription not available');
        return;
    }

    try {
        sensorSubscription = realtime.subscribeToGenericNotifications(async (data, payload) => {
            console.log('🔔 Persistent notification change detected:', payload);
            notifications = data.map(n => ({
                ...n,
                timestamp: n.createdAt || n.timestamp,
                priority: n.priority || 'low'
            }));
            applyFilters();
            updateStats();
        });

        console.log('📡 Persistent notifications subscription active');
    } catch (error) {
        console.error('❌ Failed to setup notification subscription:', error);
    }
}

// Render notifications list
function renderNotifications() {
    const container = document.getElementById('notificationsList');

    if (filteredNotifications.length === 0) {
        container.innerHTML = `
            <div style="text-align: center; padding: 60px 20px; color: #9CA3AF;">
                <i class="fas fa-bell-slash" style="font-size: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
                <p style="font-size: 18px; margin: 0;">No notifications found</p>
            </div>
        `;
        return;
    }

    container.innerHTML = filteredNotifications.map(notif => {
        const timeAgo = getTimeAgo(notif.timestamp);
        const priorityClass = notif.priority || 'low';
        const readClass = notif.read ? 'read' : 'unread';

        return `
            <div class="notification-item ${readClass} priority-${priorityClass}" data-id="${notif.id}">
                <div class="notification-icon ${priorityClass}">
                    ${getPriorityIcon(notif.priority)}
                </div>
                <div class="notification-content">
                    <div class="notification-header">
                        <h4 class="notification-title">${notif.title}</h4>
                        <span class="notification-time">${timeAgo}</span>
                    </div>
                    <p class="notification-message">${notif.message}</p>
                    <div class="notification-meta">
                        <span class="notification-type">
                            <i class="fas fa-tag"></i> ${notif.type}
                        </span>
                        <span class="notification-priority">
                            <i class="fas fa-flag"></i> ${notif.priority}
                        </span>
                    </div>
                </div>
                <div class="notification-actions">
                    ${!notif.read ? `<button class="btn-icon" onclick="markAsRead('${notif.id}')" title="Mark as read">
                        <i class="fas fa-check"></i>
                    </button>` : ''}
                    <button class="btn-icon" onclick="deleteNotification('${notif.id}')" title="Delete">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

// Update statistics
function updateStats() {
    const unread = notifications.filter(n => !n.read).length;
    const urgent = notifications.filter(n => n.priority === 'urgent').length;
    const today = notifications.filter(n => {
        const notifDate = new Date(n.timestamp);
        const todayDate = new Date();
        return notifDate.toDateString() === todayDate.toDateString();
    }).length;

    document.getElementById('unreadCount').textContent = unread;
    document.getElementById('urgentCount').textContent = urgent;
    document.getElementById('todayCount').textContent = today;
}

// Setup filter listeners
function setupFilterListeners() {
    const typeFilter = document.getElementById('typeFilter');
    const priorityFilter = document.getElementById('priorityFilter');
    const statusFilter = document.getElementById('statusFilter');

    [typeFilter, priorityFilter, statusFilter].forEach(filter => {
        filter.addEventListener('change', applyFilters);
    });
}

// Apply filters
function applyFilters() {
    const typeFilter = document.getElementById('typeFilter').value;
    const priorityFilter = document.getElementById('priorityFilter').value;
    const statusFilter = document.getElementById('statusFilter').value;

    filteredNotifications = notifications.filter(notif => {
        if (typeFilter && notif.type !== typeFilter) return false;
        if (priorityFilter && notif.priority !== priorityFilter) return false;
        if (statusFilter === 'read' && !notif.read) return false;
        if (statusFilter === 'unread' && notif.read) return false;
        return true;
    });

    renderNotifications();
}

// Reset filters
window.resetFilters = function () {
    document.getElementById('typeFilter').value = '';
    document.getElementById('priorityFilter').value = '';
    document.getElementById('statusFilter').value = '';
    applyFilters();
};

// Mark notification as read
window.markAsRead = async function (id) {
    console.log('🔄 Marking notification as read:', id);
    const { error } = await dbService.updateNotification(id, { read: true });

    if (error) {
        console.error('❌ Failed to mark as read:', error);
        return;
    }

    const notif = notifications.find(n => n.id === id);
    if (notif) {
        notif.read = true;
        renderNotifications();
        updateStats();
    }
};

// Mark all as read
window.markAllRead = async function () {
    console.log('🔄 Marking all as read...');
    const unreadIds = notifications.filter(n => !n.read).map(n => n.id);

    for (const id of unreadIds) {
        await dbService.updateNotification(id, { read: true });
    }

    notifications.forEach(n => n.read = true);
    renderNotifications();
    updateStats();
};

// Delete notification
window.deleteNotification = async function (id) {
    console.log('🔄 Deleting notification:', id);
    const { success, error } = await dbService.deleteNotification(id);

    if (!success) {
        console.error('❌ Failed to delete notification:', error);
        return;
    }

    notifications = notifications.filter(n => n.id !== id);
    filteredNotifications = filteredNotifications.filter(n => n.id !== id);
    renderNotifications();
    updateStats();
};

// Cleanup: remove local saving logic since we use DB now
function saveNotifications() {
    // No longer needed
}

// Helper: Get time ago string
function getTimeAgo(timestamp) {
    const now = new Date();
    const time = new Date(timestamp);
    const diff = now - time;

    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return time.toLocaleDateString();
}

// Helper: Get priority icon
function getPriorityIcon(priority) {
    switch (priority) {
        case 'urgent': return '<i class="fas fa-exclamation-circle"></i>';
        case 'high': return '<i class="fas fa-exclamation-triangle"></i>';
        case 'medium': return '<i class="fas fa-info-circle"></i>';
        default: return '<i class="fas fa-bell"></i>';
    }
}

// Modal functions (if needed)
// Utility: Open/Close Modals
window.openSettingsModal = function () {
    const savedSettings = JSON.parse(localStorage.getItem('notificationSettings')) || {};
    // Load state (simplified for demo)
    document.getElementById('settingsModal').style.display = 'flex';
};

window.closeSettingsModal = function () {
    document.getElementById('settingsModal').style.display = 'none';
};

window.saveSettings = function () {
    // Simply save a flag for now
    localStorage.setItem('notificationSettings', JSON.stringify({ updated: new Date() }));
    closeSettingsModal();
    showToast('Settings saved successfully', 'success');
};

// Send Notification Logic
window.openSendModal = function () {
    document.getElementById('sendModal').style.display = 'flex';
};

window.closeSendModal = function () {
    document.getElementById('sendModal').style.display = 'none';
};

window.sendNotification = async function () {
    const title = document.getElementById('sendTitle').value;
    const message = document.getElementById('sendMessage').value;
    const target = document.getElementById('sendTarget').value;

    if (!title || !message) {
        alert('Please fill in title and message');
        return;
    }

    const { error } = await dbService.createAnnouncement({
        title,
        message,
        targetAudience: target
    });

    if (error) {
        console.error('Failed to send:', error);
        alert('Failed to send notification');
    } else {
        closeSendModal();
        // Reset form
        document.getElementById('sendTitle').value = '';
        document.getElementById('sendMessage').value = '';
        loadNotifications(); // Reload to show new announcement if applicable
        alert('Notification sent successfully!');
    }
};

// Helper to show simplified toast (if not existing in main.js)
function showToast(msg, type = 'info') {
    // Placeholder if main toast logic isn't accessible, or implement simple alert
    console.log(`[TOAST] ${type}: ${msg}`);
}

