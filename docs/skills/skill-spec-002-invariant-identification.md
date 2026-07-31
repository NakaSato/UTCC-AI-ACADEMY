---
id: SKILL-SPEC-002
name: Invariant Identification
category: specification
phases: [2]
roles: [spec-owner, architect, qa, backend-engineer]
required_level: expert
agent_delegable: false
agent_trend: rising-critical
related: [SKILL-SPEC-001, SKILL-TEST-002, SKILL-ARCH-003]
review_by: 2027-01-31
---

# Invariant Identification

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-001 — Spec Writing](skill-spec-001-spec-writing.md) · [SKILL-TEST-002 — Property-Based Thinking](skill-test-002-property-thinking.md) · [SKILL-ARCH-003 — Data Modeling](skill-arch-003-data-modeling.md)

## นิยาม
ความสามารถในการระบุ **สิ่งที่ต้องเป็นจริงเสมอ** ไม่ว่าระบบจะอยู่ในสถานะไหน และเขียนมันในรูปแบบที่ทดสอบหรือบังคับได้

## ทำไมสำคัญตอนนี้
Acceptance criteria ทดสอบ "กรณีที่คิดถึง" แต่ invariant ครอบคลุม "กรณีที่ไม่ได้คิดถึง" — ซึ่งเป็นที่ที่ agent ทำพลาดมากที่สุด เพราะมันเก่งในการทำให้ตัวอย่างที่ให้ไปผ่าน แต่ไม่มีความเข้าใจ domain ที่จะรู้ว่าอะไรห้ามผิด

## ระดับ
### Foundation
- เข้าใจความต่างระหว่าง "ผลลัพธ์ที่คาดหวัง" กับ "สิ่งที่ต้องจริงเสมอ"

### Proficient
- ระบุ invariant ระดับ entity ได้ เช่น ยอดคงเหลือห้ามติดลบ
- แปลง invariant เป็น database constraint หรือ property test ได้

### Expert
- ระบุ invariant ที่ข้าม entity เช่น double-entry ledger ต้อง net เป็นศูนย์เสมอ
- ระบุ invariant ภายใต้ concurrency และ partial failure
- รู้ว่า invariant ข้อไหนควรบังคับที่ DB ข้อไหนที่ application ข้อไหนที่ test

## วิธีประเมิน
ให้ระบบโอนเงินระหว่างบัญชี แล้วถามว่า invariant มีอะไรบ้าง
- "ยอดต้องถูกต้อง" = ยังไม่ใช่ invariant เป็นความปรารถนา
- "ผลรวมของทุกบัญชีก่อนและหลังโอนต้องเท่ากัน" = Proficient
- เพิ่ม "แม้ transaction ล้มกลางคัน" และ "แม้มีสอง request พร้อมกันด้วย key เดียวกัน" = Expert

## เส้นทางพัฒนา
1. หยิบ domain ที่คุ้นเคย เขียน invariant ให้ได้ 10 ข้อ แล้วให้คนอื่นหาทางละเมิดแต่ละข้อ
2. ฝึกเขียน property-based test แทน example-based test สำหรับ logic ที่ซับซ้อน
3. ทุกครั้งที่เกิด bug ให้ถามว่า "invariant ข้อไหนที่ถ้ามีอยู่จะจับ bug นี้ได้"
4. ศึกษา double-entry bookkeeping — เป็นตัวอย่าง invariant ที่ออกแบบมาดีที่สุดในประวัติศาสตร์

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียน property test จาก invariant ที่ให้ไว้, แปลง invariant เป็น constraint SQL
- **Agent ทำแทนไม่ได้:** ระบุว่า invariant คืออะไร — เพราะมันมาจากความเข้าใจ domain ไม่ใช่จากข้อความ

## สัญญาณว่าทีมขาดทักษะนี้
- Bug ประเภท "ข้อมูลอยู่ในสถานะที่เป็นไปไม่ได้" เกิดเป็นระยะ
- Test ทั้งหมดเป็น example-based
- Spec มี AC แต่ไม่มี section invariant เลย
