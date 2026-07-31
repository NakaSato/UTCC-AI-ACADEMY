---
id: SKILL-SPEC-003
name: Ambiguity Detection
category: specification
phases: [2]
roles: [spec-owner, business-analyst, qa, tech-lead]
required_level: expert
agent_delegable: true
agent_trend: rising-critical
related: [SKILL-SPEC-001, SKILL-AI-001]
review_by: 2027-01-31
---

# Ambiguity Detection

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-001 — Spec Writing](skill-spec-001-spec-writing.md) · [SKILL-AI-001 — Context Engineering](skill-ai-001-context-engineering.md)

## นิยาม
ความสามารถในการอ่านเอกสารแล้วเห็น **สิ่งที่ยังไม่ได้ถูกเขียน** — เงื่อนไขขอบ กรณีว่าง กรณีขัดแย้ง และจุดที่คนสองคนจะตีความต่างกัน

## ทำไมสำคัญตอนนี้
ความคลุมเครือที่ไหลลงไปถึงชั้น implementation มีต้นทุนแพงขึ้นแบบทวีคูณ และตอนนี้แพงกว่าเดิมเพราะ agent จะแปลงความคลุมเครือเป็นโค้ดที่ดูดีได้ภายในไม่กี่นาที ทำให้ตรวจจับยากกว่าตอนที่มนุษย์เขียนช้าๆ แล้วเดินมาถาม

## ระดับ
### Foundation
- ถามคำถามเมื่อเจอสิ่งที่ไม่เข้าใจ

### Proficient
- ตรวจสอบอย่างเป็นระบบ: กรณีว่าง, ค่าลบ, ค่าซ้ำ, timeout, concurrent, สิทธิ์
- เห็นความขัดแย้งระหว่างสองย่อหน้าในเอกสารเดียวกัน

### Expert
- เห็นสิ่งที่ไม่ได้เขียนเลยและควรมี (missing requirement ไม่ใช่แค่ unclear requirement)
- จัดลำดับความคลุมเครือตามผลกระทบต่อ scope ไม่ใช่ตามลำดับที่เจอ
- รู้ว่าความคลุมเครือข้อไหนควรแก้ตอนนี้ และข้อไหนปล่อยไว้ได้จนกว่าจะเจอจริง

## วิธีประเมิน
ให้ spec ที่มีช่องโหว่ฝังไว้ 8 จุด (บางจุดเป็น missing requirement) ให้เวลา 15 นาที
- เจอ 3–4 จุด = Proficient
- เจอ 6+ จุด และจัดลำดับตามผลกระทบได้ = Expert
- เจอเฉพาะจุดที่เขียนกำกวม แต่ไม่เห็นสิ่งที่หายไป = ยังไม่ถึง Expert

## เส้นทางพัฒนา
1. ทำ checklist ส่วนตัว: null/empty, boundary, duplicate, concurrent, timeout, permission, i18n, migration ของข้อมูลเดิม
2. ทุกครั้งที่เกิด bug จาก requirement ให้เพิ่มรูปแบบนั้นเข้า checklist
3. **ใช้ agent เป็นคู่ซ้อม** — ให้มันหาช่องว่างใน spec ของคุณ แล้วดูว่ามันเห็นอะไรที่คุณไม่เห็น
4. ฝึกอ่าน spec ของคนอื่นโดยตั้งเป้าหาช่องว่างให้ได้ 5 จุดก่อนแสดงความเห็น

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** **ข้อนี้ agent ทำได้ดีมากและควรใช้เต็มที่** — prompt ที่ให้ผลตอบแทนสูงสุดคือ "อ่าน spec นี้ แล้วบอกว่ามีอะไรที่ยังไม่ตอบ เรียงตามผลกระทบต่อ scope โดยยังไม่ต้องเขียนโค้ด"
- **Agent ทำแทนไม่ได้:** ตัดสินว่าความคลุมเครือข้อไหนสำคัญพอที่จะหยุดงานเพื่อแก้

## สัญญาณว่าทีมขาดทักษะนี้
- คำถามส่วนใหญ่เกิดตอน implement ไม่ใช่ตอน review spec
- Agent block rate ต่ำมาก (มันเดาแทนที่จะถาม เพราะไม่มีอะไรให้สังเกตว่าคลุมเครือ)
