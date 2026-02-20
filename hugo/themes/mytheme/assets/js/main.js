// ==========================================
// テーマ切り替え機能（必要最低限）
// ==========================================

(function() {
  'use strict';

  // テーマを取得（localStorage → システム設定 → デフォルト）
  function getTheme() {
    const stored = localStorage.getItem('theme');
    if (stored) return stored;
    
    // システムのダークモード設定を確認
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }
    
    return 'light';
  }

  // テーマを適用
  function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }

  // テーマを切り替え
  function toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
    setTheme(next);
  }

  // ページ読み込み時の初期化
  document.addEventListener('DOMContentLoaded', function() {
    const button = document.getElementById('theme-toggle');
    
    if (button) {
      button.addEventListener('click', toggleTheme);
    }

    // 初期テーマを設定（FOUCスクリプトで既に設定済みだが念のため）
    const theme = getTheme();
    setTheme(theme);
  });

  // システムのテーマ変更を監視（オプション）
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
      // ユーザーが手動で設定していない場合のみ自動追従
      if (!localStorage.getItem('theme')) {
        setTheme(e.matches ? 'dark' : 'light');
      }
    });
  }

})();


// ==========================================
// ページトップリンク表示制御
// ==========================================

(function() {
  'use strict';

  // スクロール可能かどうかを判定
  function checkScrollable() {
    const hasScroll = document.documentElement.scrollHeight > document.documentElement.clientHeight;
    document.body.classList.toggle('no-scroll', !hasScroll);
  }

  // ページ読み込み時とリサイズ時にチェック
  document.addEventListener('DOMContentLoaded', function() {
    checkScrollable();
  });

  window.addEventListener('resize', function() {
    checkScrollable();
  });

})();