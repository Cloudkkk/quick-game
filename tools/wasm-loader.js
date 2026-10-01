/* Preserve the compressed download even when a host drops Content-Encoding. */
(function () {
  'use strict';
  const originalFetch = window.fetch.bind(window);
  window.fetch = async function (input, init) {
    const url = new URL(typeof input === 'string' ? input : input.url || String(input), document.baseURI);
    if (url.origin !== location.origin || !url.pathname.endsWith('/index.wasm')) {
      return originalFetch(input, init);
    }
    const response = await originalFetch(input, init);
    if (!response.ok) return response;
    const bytes = new Uint8Array(await response.arrayBuffer());
    let body = bytes;
    if (bytes[0] === 0x1f && bytes[1] === 0x8b) {
      if (typeof DecompressionStream === 'undefined') {
        throw new Error('请使用最新版 Chrome、Brave 或 Firefox 打开游戏（浏览器不支持资源解压）。');
      }
      body = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer());
    }
    if (body[0] !== 0 || body[1] !== 0x61 || body[2] !== 0x73 || body[3] !== 0x6d) {
      throw new Error('游戏资源下载不完整，请刷新重试。');
    }
    const headers = new Headers(response.headers);
    headers.delete('Content-Encoding');
    headers.delete('Content-Length');
    headers.set('Content-Type', 'application/wasm');
    headers.set('Content-Length', String(body.byteLength));
    return new Response(body, { status: response.status, statusText: response.statusText, headers });
  };
}());
