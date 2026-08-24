const express = require('express');
const app = express();
app.use(express.json());

// Lưu trữ các server có Boss: { jobId: string, timestamp: number }
let bossServers = [];

const BOSS_TTL_MS = 15 * 60 * 1000; // Server có hiệu lực trong 15 phút (thời gian đêm/boss tồn tại)

// Hàm dọn dẹp các server hết hạn hoặc hết Boss
function cleanExpiredServers() {
  const now = Date.now();
  bossServers = bossServers.filter(s => (now - s.timestamp) < BOSS_TTL_MS);
}

// 1. API: Client báo cáo server ĐANG CÓ Cursed Captain
app.post('/api/report', (req, res) => {
  const { jobId } = req.body;
  if (!jobId) return res.status(400).json({ success: false, message: "Thiếu Job ID" });

  cleanExpiredServers();

  // Kiểm tra xem đã có trong danh sách chưa
  const exists = bossServers.some(s => s.jobId === jobId);
  if (!exists) {
    bossServers.push({ jobId, timestamp: Date.now() });
    console.log(`[+] Đã thêm server có Boss: ${jobId}`);
  }

  res.json({ success: true, count: bossServers.length });
});

// 2. API: Lấy server hop tiếp theo (Tránh các server client đã đi qua)
app.post('/api/get-hop-server', (req, res) => {
  const { visitedJobIds } = req.body; // Danh sách JobID mà client gửi lên (các server đã vào)
  const visitedSet = new Set(visitedJobIds || []);

  cleanExpiredServers();

  // Tìm server có Boss mà Client CHƯA TỪNG VÀO
  const validServer = bossServers.find(s => !visitedSet.has(s.jobId));

  if (!validServer) {
    return res.json({ 
      success: false, 
      message: "Không có server nào mới có Cursed Captain lúc này" 
    });
  }

  res.json({
    success: true,
    jobId: validServer.jobId
  });
});

// 3. API: Xóa server khi Boss đã bị tiêu diệt
app.post('/api/remove', (req, res) => {
  const { jobId } = req.body;
  bossServers = bossServers.filter(s => s.jobId !== jobId);
  res.json({ success: true, message: "Đã xóa server khỏi danh sách" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Hop API running on port ${PORT}`));
