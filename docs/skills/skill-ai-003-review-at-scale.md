---
id: SKILL-AI-003
name: Review at Scale
category: ai-era
phases: [3]
roles: [tech-lead, agent-orchestrator, engineering-manager]
required_level: expert
agent_delegable: false
agent_trend: new
related: [SKILL-AI-002, SKILL-BLD-003]
review_by: 2027-01-31
---

# Review at Scale

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-AI-002 — Agent Output Verification](skill-ai-002-agent-output-verification.md) · [SKILL-BLD-003 — Release Risk Assessment](skill-bld-003-release-risk-assessment.md)

## นิยาม
ความสามารถในการจัดการการตรวจสอบเมื่อปริมาณงานที่ต้องตรวจมากกว่าความสามารถในการอ่านทั้งหมด — คือการตัดสินว่า **จะอ่านตรงไหนอย่างละเอียด และตรงไหนพอเชื่อ automation ได้**

## ทำไมสำคัญตอนนี้
เมื่อ throughput เพิ่ม 5–10 เท่า การอ่านทุก diff อย่างละเอียดเป็นไปไม่ได้ ทีมส่วนใหญ่จึงเปลี่ยนเป็น rubber-stamp โดยไม่มีใครตัดสินใจให้มันเกิด ทักษะนี้คือการทำให้การจัดสรรความสนใจเป็นเรื่องที่ตั้งใจ ไม่ใช่เรื่องที่ยอมแพ้

## ระดับ
### Foundation
- รีวิวทีละ PR ตามลำดับที่เข้ามา

### Proficient
- จัดลำดับตามความเสี่ยง ไม่ใช่ตามเวลาที่ส่งเข้ามา
- ใช้ผลของ gate ที่ผ่านมาแล้วเพื่อไม่ตรวจซ้ำสิ่งที่ automation ตรวจไปแล้ว
- ขอให้แตกงานเมื่อ diff ใหญ่เกินกว่าจะตรวจได้จริง

### Expert
- ออกแบบ risk tier และ policy ที่ทำให้ความสนใจของมนุษย์ไปตกที่จุดที่คุ้มที่สุด
- จัดการ capacity: รู้ว่าทีมตรวจได้กี่ชิ้นต่อวัน แล้วตั้ง WIP limit จากตัวเลขนั้น
- ตรวจจับสัญญาณ rubber-stamp ในทีมและแก้ที่ระบบ ไม่ใช่ที่คน

## วิธีประเมิน
ให้สถานการณ์: มี 25 PR รอรีวิว ทีมมีเวลารวม 4 ชั่วโมงวันนี้ ถามว่าจะจัดการอย่างไร
- รีวิวเรียงตามลำดับ = Foundation
- จัดลำดับตามความเสี่ยงและขอแตกงานที่ใหญ่เกิน = Proficient
- ตั้งคำถามว่าทำไมถึงมี 25 PR ทั้งที่ capacity คือ 9 และเสนอ backpressure = Expert

## เส้นทางพัฒนา
1. วัดว่าทีมรีวิวได้จริงกี่ชิ้นต่อวัน แล้วตั้งเพดาน PR เปิดค้างจากตัวเลขนั้น
2. จัด risk tier ให้ repo ปัจจุบันจาก path ที่แตะ
3. วัด review depth (เวลา ÷ ขนาด diff) รายสัปดาห์ ดูแนวโน้ม
4. ทดลอง auto-merge กับ Tier A พร้อม audit sampling แล้ววัด escaped defect

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** สรุป diff, ชี้จุดที่น่าสงสัย, จัดกลุ่ม PR ตามความเสี่ยง, ตรวจ policy อัตโนมัติ
- **Agent ทำแทนไม่ได้:** ตัดสินว่าอะไรพอเชื่อได้ — เพราะนั่นคือการรับความเสี่ยง

## สัญญาณว่าทีมขาดทักษะนี้
- PR ค้างเกิน capacity อย่างต่อเนื่อง
- Review depth ลดลงทุกเดือน
- ทุก PR ได้รับความสนใจเท่ากันไม่ว่าจะแตะอะไร
