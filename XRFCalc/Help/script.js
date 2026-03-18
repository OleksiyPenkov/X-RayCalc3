/* XRFCalc — Help Shared JavaScript */

// ── Back to top ──
(function() {
  var btn = document.getElementById('backToTop');
  if (!btn) return;
  window.addEventListener('scroll', function() {
    btn.classList.toggle('visible', window.scrollY > 400);
  });
})();

// ── Highlight current page in sidebar ──
(function() {
  var path = location.pathname.split('/').pop() || 'index.html';
  var links = document.querySelectorAll('.sidebar a');
  links.forEach(function(a) {
    var href = a.getAttribute('href');
    if (href && href.split('/').pop() === path) {
      a.classList.add('active');
    }
  });
})();

// ── Search / filter TOC ──
function filterTOC(query) {
  var links = document.querySelectorAll('.sidebar a');
  var q = query.toLowerCase();
  if (!q) {
    links.forEach(function(a) { a.style.display = ''; });
    return;
  }
  links.forEach(function(a) {
    var text = a.textContent.toLowerCase();
    a.style.display = text.indexOf(q) >= 0 ? '' : 'none';
  });
}

// ── Filter index page cards ──
function filterCards(query) {
  var cards = document.querySelectorAll('.card');
  var q = query.toLowerCase();
  if (!q) {
    cards.forEach(function(c) { c.style.display = ''; });
    return;
  }
  cards.forEach(function(c) {
    var text = c.textContent.toLowerCase();
    c.style.display = text.indexOf(q) >= 0 ? '' : 'none';
  });
}
