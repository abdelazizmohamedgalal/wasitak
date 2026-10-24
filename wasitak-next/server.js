import http from "node:http";
import { DatabaseSync } from "node:sqlite";

const port = Number(process.env.PORT || 3000);
const db = new DatabaseSync(process.env.DB_PATH || "./wasitak.sqlite");
db.exec(`
  CREATE TABLE IF NOT EXISTS listings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT NOT NULL CHECK(category IN ('housing','jobs')),
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    area TEXT NOT NULL DEFAULT 'بورسعيد',
    price REAL,
    contact_phone TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','published','rejected')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  );
  CREATE INDEX IF NOT EXISTS idx_listings_status_category ON listings(status, category, created_at);
`);

const json = (res, status, data) => {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8", "access-control-allow-origin": "*", "access-control-allow-methods": "GET,POST,OPTIONS", "access-control-allow-headers": "content-type" });
  res.end(JSON.stringify(data));
};
const server = http.createServer(async (req, res) => {
  if (req.method === "OPTIONS") { res.writeHead(204); return res.end(); }
  const url = new URL(req.url || "/", "http://localhost");
  if (req.method === "GET" && url.pathname === "/api/health") return json(res, 200, { ok: true, app: "wasitak-next" });
  if (req.method === "GET" && url.pathname === "/api/listings") {
    const category = url.searchParams.get("category");
    const rows = category && ["housing","jobs"].includes(category)
      ? db.prepare("SELECT id,category,title,description,area,price,created_at FROM listings WHERE status='published' AND category=? ORDER BY created_at DESC").all(category)
      : db.prepare("SELECT id,category,title,description,area,price,created_at FROM listings WHERE status='published' ORDER BY created_at DESC").all();
    return json(res, 200, { items: rows });
  }
  if (req.method === "POST" && url.pathname === "/api/listings") {
    let raw = "";
    for await (const chunk of req) { raw += chunk; if (raw.length > 100_000) return json(res, 413, { error: "حجم الطلب كبير" }); }
    let data;
    try { data = JSON.parse(raw || "{}"); } catch { return json(res, 400, { error: "صيغة JSON غير صحيحة" }); }
    const category = data.category;
    const title = String(data.title || "").trim();
    const description = String(data.description || "").trim();
    const area = String(data.area || "بورسعيد").trim().slice(0,120);
    const phone = String(data.contact_phone || "").trim();
    const price = data.price == null || data.price === "" ? null : Number(data.price);
    if (!["housing","jobs"].includes(category) || title.length < 4 || title.length > 120 || phone.length < 8 || phone.length > 25 || (price !== null && (!Number.isFinite(price) || price < 0))) {
      return json(res, 400, { error: "راجع نوع الإعلان والعنوان ورقم التواصل والسعر" });
    }
    const result = db.prepare("INSERT INTO listings(category,title,description,area,price,contact_phone,status) VALUES(?,?,?,?,?,?,'pending')").run(category,title,description.slice(0,5000),area,price,phone);
    return json(res, 201, { ok: true, id: Number(result.lastInsertRowid), status: "pending", message: "تم استلام الإعلان وسيظهر بعد المراجعة" });
  }
  if (req.method === "GET" && url.pathname === "/") {
    res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
    return res.end(`<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>وسيطك</title><style>body{font-family:Arial,sans-serif;background:#f4f8f5;color:#183326;margin:0}header{background:#16834a;color:white;padding:28px 18px}main{max-width:760px;margin:24px auto;padding:0 16px}.card{background:white;border-radius:16px;padding:20px;margin:14px 0;box-shadow:0 3px 14px #18332612}button{background:#16834a;color:white;border:0;border-radius:10px;padding:12px 18px;font-size:16px}a{color:#16834a}</style><header><h1>وسيطك</h1><p>إعلانات السكن والوظائف في بورسعيد</p></header><main><section class="card"><h2>أهلاً بيك في وسيطك</h2><p>نسخة أولية مستقلة. الإعلانات الجديدة تذهب للمراجعة قبل النشر.</p><button onclick="load()">عرض الإعلانات المنشورة</button><div id="items"></div></section><section class="card"><h2>إضافة إعلان</h2><form id="f"><label>نوع الإعلان <select name="category"><option value="housing">سكن</option><option value="jobs">وظيفة</option></select></label><p><input name="title" required minlength="4" maxlength="120" placeholder="عنوان الإعلان" style="width:95%;padding:10px"></p><p><textarea name="description" placeholder="التفاصيل" style="width:95%;padding:10px"></textarea></p><p><input name="area" value="بورسعيد" placeholder="المنطقة" style="width:95%;padding:10px"></p><p><input name="price" type="number" min="0" placeholder="السعر إن وجد" style="width:95%;padding:10px"></p><p><input name="contact_phone" required placeholder="رقم التواصل" style="width:95%;padding:10px"></p><button>إرسال للمراجعة</button><p id="msg"></p></form></section></main><script>async function load(){let r=await fetch('/api/listings');let d=await r.json();document.getElementById('items').innerHTML=d.items.length?d.items.map(x=>'<article class="card"><h3>'+esc(x.title)+'</h3><p>'+esc(x.description||'')+'</p><small>'+esc(x.area)+' · '+(x.price==null?'السعر عند التواصل':x.price+' جنيه')+'</small></article>').join(''):'<p>لا توجد إعلانات منشورة حتى الآن.</p>'}function esc(s){return String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]))}document.getElementById('f').onsubmit=async e=>{e.preventDefault();let d=Object.fromEntries(new FormData(e.target));d.price=d.price||null;let r=await fetch('/api/listings',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(d)});let x=await r.json();document.getElementById('msg').textContent=x.message||x.error||'حصل خطأ';if(r.ok)e.target.reset()};</script></html>`);
  }
  return json(res, 404, { error: "المسار غير موجود" });
});
server.listen(port, "0.0.0.0", () => console.log(`Wasitak Next listening on ${port}`));
