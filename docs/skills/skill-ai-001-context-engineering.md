---
id: SKILL-AI-001
name: Context Engineering
category: ai-era
phases: [3]
roles: [backend-engineer, frontend-engineer, agent-orchestrator, spec-owner]
required_level: proficient
agent_delegable: false
agent_trend: new
related: [SKILL-SPEC-001, SKILL-AI-002]
review_by: 2027-01-31
---

# Context Engineering

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-001 — Spec Writing](skill-spec-001-spec-writing.md) · [SKILL-AI-002 — Agent Output Verification](skill-ai-002-agent-output-verification.md)

## นิยาม
ความสามารถในการจัดเตรียมบริบทให้ agent ทำงานได้ถูกต้อง — เลือกว่าอะไรควรอยู่ในบริบท อะไรไม่ควร ลำดับการทำงานที่ให้ผลดีที่สุด และการแบ่งงานให้อยู่ในขนาดที่ agent ทำได้ดี

## ทำไมสำคัญตอนนี้
ทักษะใหม่ทั้งหมด และเป็นตัวคูณของทุกอย่างที่ agent ทำ ความต่างระหว่างคนที่มีทักษะนี้กับไม่มีอยู่ที่ผลลัพธ์ต่างกันหลายเท่าจาก agent ตัวเดียวกัน

## ระดับ
### Foundation
- เขียนคำสั่งที่ชัดเจน ระบุสิ่งที่ต้องการและรูปแบบผลลัพธ์
- แนบไฟล์ที่เกี่ยวข้องให้

### Proficient
- **แบ่งงานให้เล็กพอที่ตรวจสอบได้** — เป็นตัวชี้วัดสำคัญที่สุดของระดับนี้
- เลือก context ที่เกี่ยวข้องจริงแทนที่จะโยนทั้ง repo (ลด token cost และลดโอกาสสับสน)
- ใช้ลำดับที่ถูกต้อง: ให้หาช่องว่างก่อน → ยืนยัน → ค่อยให้ implement
- ให้ตัวอย่างของสิ่งที่ต้องการและสิ่งที่ไม่ต้องการ

### Expert
- ออกแบบ `AGENTS.md` / working agreement ที่ทำให้ทั้งทีมได้ผลดีขึ้น ไม่ใช่แค่ตัวเอง
- รู้ว่างานประเภทไหนควรให้ agent ทำ และประเภทไหนทำเองเร็วกว่า
- จัดโครงสร้าง repo และเอกสารให้ agent ทำงานได้ดีตั้งแต่ต้น (frontmatter, boundary, naming)

## วิธีประเมิน
ให้งานเดียวกันกับสองคน ให้ใช้ agent ตัวเดียวกัน แล้ววัด:
- จำนวนรอบที่ต้องแก้ก่อนได้ผลที่ใช้ได้
- ขนาดของ diff ที่ได้ (ใหญ่เกินไป = แบ่งงานไม่เป็น)
- จำนวนคำถามที่ agent ถามกลับ (ศูนย์ในงานที่ซับซ้อน = บริบทไม่พอจนมันเดา)

## เส้นทางพัฒนา
1. เริ่มทุกงานด้วย "อ่าน spec นี้แล้วบอกว่ามีอะไรที่ยังไม่ตอบ" ก่อนสั่ง implement เสมอ
2. ฝึกแบ่งงานให้ diff ไม่เกิน 300 บรรทัดต่อครั้ง
3. เขียน `AGENTS.md` ให้โปรเจกต์ตัวเอง แล้ววัดว่า rework ลดลงไหม
4. เก็บสถิติว่างานประเภทไหนที่ agent ทำแล้วต้องแก้เยอะที่สุด แล้วเลิกให้มันทำ

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ไม่มี — นี่คือทักษะในการใช้ agent
- **หมายเหตุ:** agent ช่วยปรับปรุง prompt ของตัวเองได้ แต่การตัดสินว่าผลลัพธ์ดีขึ้นจริงไหมยังเป็นของมนุษย์

## สัญญาณว่าทีมขาดทักษะนี้
- Diff จาก agent ใหญ่จนไม่มีใครอยากรีวิว
- ต้องแก้งานเดิมซ้ำหลายรอบ
- Rework rate สูงกว่า 25%
