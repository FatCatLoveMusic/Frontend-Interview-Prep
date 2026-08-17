(function () {
  // 首页搜索
  var box = document.getElementById('hsearch');
  if (box && window.TOPIC_INDEX) {
    var res = document.getElementById('hresults');
    box.addEventListener('input', function () {
      var kw = box.value.trim().toLowerCase();
      res.innerHTML = '';
      res.classList.remove('has-results');
      if (!kw) { return; }
      var hits = window.TOPIC_INDEX.filter(function (it) {
        return it.t.toLowerCase().indexOf(kw) >= 0 || it.c.some(function (c) { return c.toLowerCase().indexOf(kw) >= 0; });
      });
      if (hits.length === 0) {
        var empty = document.createElement('div');
        empty.className = 'search-empty';
        empty.textContent = '未找到匹配的题目';
        res.appendChild(empty);
        res.classList.add('has-results');
        return;
      }
      hits.slice(0, 50).forEach(function (it) {
        var a = document.createElement('a');
        a.className = 'search-item';
        a.href = 'questions/' + it.n + '.html';
        var s = document.createElement('span');
        s.className = 'search-t';
        s.textContent = it.t;
        var c = document.createElement('span');
        c.className = 'search-c';
        c.textContent = it.c.join(' / ');
        a.appendChild(s); a.appendChild(c);
        res.appendChild(a);
      });
      res.classList.add('has-results');
    });
    document.addEventListener('click', function (e) {
      if (!res.contains(e.target) && e.target !== box) { res.classList.remove('has-results'); }
    });
  }
  // 分类页过滤
  var filter = document.getElementById('qfilter');
  if (filter) {
    var rows = Array.prototype.slice.call(document.querySelectorAll('.q-row'));
    filter.addEventListener('input', function () {
      var kw = filter.value.trim().toLowerCase();
      var count = 0;
      rows.forEach(function (r) {
        var show = !kw || (r.getAttribute('data-t') || '').toLowerCase().indexOf(kw) >= 0;
        r.style.display = show ? '' : 'none';
        if (show) { count++; }
      });
      var tip = document.getElementById('filter-tip');
      if (tip) { tip.textContent = kw ? ('匹配 ' + count + ' 题') : ''; }
    });
  }
})();