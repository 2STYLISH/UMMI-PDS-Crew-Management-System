/* ============================================================
   UMMI Crew Management Module — site.js
   Enterprise UI helpers
   ============================================================ */

/* ── Top-nav dropdown toggle ── */
function toggleDropdown(el) {
    // el could be a button inside .topnav-dropdown, or the .topnav-dropdown-toggle div itself
    var dropdown = el.closest('.topnav-dropdown');
    if (!dropdown) return;
    var menu = dropdown.querySelector('.topnav-dropdown-menu');
    if (!menu) return;
    var isOpen = menu.classList.contains('show');
    // Close all open dropdowns first
    document.querySelectorAll('.topnav-dropdown-menu.show').forEach(function(m) {
        m.classList.remove('show');
    });
    if (!isOpen) {
        menu.classList.add('show');
    }
}

// Close dropdowns when clicking outside
document.addEventListener('click', function(e) {
    if (!e.target.closest('.topnav-dropdown') && !e.target.closest('.topnav-user-menu')) {
        document.querySelectorAll('.topnav-dropdown-menu.show').forEach(function(m) {
            m.classList.remove('show');
        });
    }
});

// Highlight active nav link
(function() {
    var path = window.location.pathname.toLowerCase();
    document.querySelectorAll('.topnav-link[href]').forEach(function(link) {
        if (link.getAttribute('href') && path.indexOf(link.getAttribute('href').replace('~/', '/').toLowerCase().split('?')[0]) !== -1) {
            link.classList.add('active');
        }
    });
    // Mark dropdown parent as active if a child is active
    document.querySelectorAll('.topnav-dropdown').forEach(function(dd) {
        var activeChild = dd.querySelector('.topnav-dropdown-item.active');
        if (activeChild) {
            var toggle = dd.querySelector('.topnav-dropdown-toggle');
            if (toggle) toggle.classList.add('active');
        }
    });
})();

/* ── Toast notification helper ── */
function showToast(message, type) {
    var container = document.getElementById('toastContainer');
    if (!container) return;
    var toast = document.createElement('div');
    toast.className = 'toast' + (type ? ' toast-' + type : '');
    toast.innerHTML = '<i class="fa fa-' + (type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle') + '"></i> ' + message;
    container.appendChild(toast);
    setTimeout(function() {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(20px)';
        toast.style.transition = 'all 0.25s ease';
        setTimeout(function() { toast.remove(); }, 300);
    }, 3500);
}


/* ── Clipboard copy (WBS 1.2.6) ── */
function copyToClipboard(text, btn) {
    navigator.clipboard.writeText(text).then(function () {
        btn.classList.add('copied');
        var original = btn.innerText;
        btn.innerText = 'Copied!';
        setTimeout(function () {
            btn.classList.remove('copied');
            btn.innerText = original;
        }, 2000);
    }).catch(function () {
        // Fallback for older browsers
        var ta = document.createElement('textarea');
        ta.value = text;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
        btn.classList.add('copied');
        btn.innerText = 'Copied!';
        setTimeout(function () {
            btn.classList.remove('copied');
        }, 2000);
    });
}

/* ── Show / hide loading overlay ── */
function showLoading() {
    var el = document.getElementById('loadingOverlay');
    if (el) el.style.display = 'flex';
}
function hideLoading() {
    var el = document.getElementById('loadingOverlay');
    if (el) el.style.display = 'none';
}

/* ── Alert auto-dismiss ── */
document.addEventListener('DOMContentLoaded', function () {
    var alerts = document.querySelectorAll('.alert-auto');
    alerts.forEach(function (a) {
        setTimeout(function () {
            a.style.opacity = '0';
            a.style.transition = 'opacity .4s';
            setTimeout(function () { a.remove(); }, 400);
        }, 4000);
    });
});

/* ── Sidebar mobile toggle ── */
function toggleSidebar() {
    var sb = document.querySelector('.sidebar');
    if (sb) sb.classList.toggle('open');
}

/* ── Province -> City cascade (WBS 1.1.3) — called on dropdown change ── */
function cascadeCity(provinceDropId, cityDropId) {
    // Server-side postback handles this; this is a no-op placeholder
    // for Alpine.js wiring if needed in future
}

/* ── Alpine.js data stores ── */
document.addEventListener('alpine:init', function () {

    /* Search filter panel state */
    Alpine.store('filterPanel', {
        expanded: true,
        toggle: function () { this.expanded = !this.expanded; }
    });

    /* Link modal state (WBS 1.3.10) */
    Alpine.store('linkModal', {
        visible: false,
        link: '',
        show: function (url) { this.link = url; this.visible = true; },
        hide: function () { this.visible = false; }
    });
});

/* ── Document open popup (WBS 1.2.16) ── */
function openDocument(url) {
    var w = window.open(url, 'docViewer',
        'width=900,height=700,scrollbars=yes,resizable=yes');
    if (w) w.focus();
}

/* ── Print current page ── */
function printPage() {
    window.print();
}

/* ── Confirm before destructive action ── */
function confirmAction(message) {
    return confirm(message || 'Are you sure?');
}

/* ── Format date to readable string ── */
function formatDate(dateStr) {
    if (!dateStr) return '';
    var d = new Date(dateStr);
    return d.toLocaleDateString('en-PH', { year: 'numeric', month: 'long', day: 'numeric' });
}

/* ── BMI classification (WBS 1.2.3) ── */
function bmiClass(bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25)   return 'Normal';
    if (bmi < 30)   return 'Overweight';
    return 'Obese';
}

/* ── Copy generated link to clipboard (WBS 1.3.10) ── */
function copyLink(linkText) {
    copyToClipboard(linkText, document.getElementById('btnCopyLink') || document.body);
}
