---
id: SKILL-AI-004
name: Agent Orchestration
category: ai-era
phases: [3]
roles: [agent-orchestrator, tech-lead, platform-engineer]
required_level: proficient
agent_delegable: false
agent_trend: new
related: [SKILL-AI-001, SKILL-AI-003, SKILL-ARCH-004]
review_by: 2027-01-31
---

# Agent Orchestration

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-AI-001 — Context Engineering](skill-ai-001-context-engineering.md) · [SKILL-AI-003 — Review at Scale](skill-ai-003-review-at-scale.md) · [SKILL-ARCH-004 — Threat Modeling](skill-arch-004-threat-modeling.md)

## นิยาม
ความสามารถในการตั้งค่าและควบคุมการทำงานของ agent ในระดับระบบ — ขอบเขตเครื่องมือ สิทธิ์ งบประมาณ ความขนาน และกลไกหยุดฉุกเฉิน

## ทำไมสำคัญตอนนี้
เป็นทักษะใหม่ที่ยังไม่มีใครสอน แต่จำเป็นทันทีที่ agent ทำงานเกินหนึ่งตัวหรือทำงานโดยไม่มีคนนั่งดูตลอดเวลา — ซึ่งเป็นสภาพที่ทุกทีมจะไปถึงภายในไม่กี่เดือน

## ระดับ
### Foundation
- ตั้งค่า agent ให้ทำงานกับ repo ได้
- รู้ว่า agent เข้าถึงอะไรได้บ้าง

### Proficient
- กำหนด tool scope และ credential ที่จำกัดตามหลัก least privilege
- ตั้งเพดานงบประมาณและความขนานที่ผูกกับ capacity ของการตรวจสอบ
- ตั้ง identity แยกให้ agent เพื่อให้ audit trail แยกจากมนุษย์ได้

### Expert
- ออกแบบ admission control และ backpressure ที่ทำงานจริง
- ออกแบบ kill switch ที่ทำงานได้แม้ระบบอื่นล่ม และทดสอบสม่ำเสมอ
- ป้องกัน prompt injection ในระดับสถาปัตยกรรม (แยก instruction ออกจาก data, egress allowlist)

## วิธีประเมิน
ถาม:
1. "ถ้า agent เริ่มทำสิ่งที่ผิดตอนนี้ คุณหยุดมันได้ภายในกี่วินาที"
2. "agent มี credential อะไรบ้าง และเข้าถึง production ได้ไหม"
3. "ถ้ามีคนใส่ข้อความในไฟล์ที่ agent อ่าน สั่งให้มันทำอย่างอื่น จะเกิดอะไร"

ตอบข้อ 3 ไม่ได้ = ยังไม่ถึง Proficient สำหรับระบบที่ agent ทำงานอัตโนมัติ

## เส้นทางพัฒนา
1. ตรวจสอบว่า agent ในโปรเจกต์ปัจจุบันเข้าถึงอะไรได้บ้างจริงๆ
2. ตั้ง identity และ credential แยกให้ agent
3. ตั้งเพดาน PR เปิดค้าง แล้วดูว่าพฤติกรรมทีมเปลี่ยนไหม
4. ทดสอบ kill switch เป็น game day ทุกไตรมาส

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ไม่ควรให้ทำ — agent ที่กำหนดขอบเขตของตัวเองคือความเสี่ยงเชิงโครงสร้าง
- **หมายเหตุ:** agent ช่วยเขียน config ได้ แต่การอนุมัติต้องเป็นของมนุษย์

## สัญญาณว่าทีมขาดทักษะนี้
- ไม่มี kill switch หรือมีแต่ไม่เคยทดสอบ
- agent ใช้ credential เดียวกับมนุษย์
- ไม่มีเพดานงบประมาณ
