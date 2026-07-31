---
id: SKILL-TEST-001
name: Test Design
category: testing
phases: [2, 4]
roles: [qa, sdet, spec-owner, backend-engineer]
required_level: expert
agent_delegable: false
agent_trend: rising-critical
related: [SKILL-SPEC-002, SKILL-TEST-002]
review_by: 2027-01-31
---

# Test Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-002 — Invariant Identification](skill-spec-002-invariant-identification.md) · [SKILL-TEST-002 — Property-Based Thinking](skill-test-002-property-thinking.md)

## นิยาม
ความสามารถในการออกแบบชุดทดสอบที่ **พิสูจน์ว่าระบบถูก** ไม่ใช่แค่ **แสดงว่าระบบทำงาน** และเลือกได้ว่าอะไรควรทดสอบที่ระดับไหน

## ทำไมสำคัญตอนนี้
เมื่อ agent เขียน implementation ส่วนใหญ่ test กลายเป็นนิยามเดียวของคำว่า "ถูก" ที่มนุษย์ควบคุมอยู่ ถ้า agent เขียน test เองด้วย ระบบจะกลายเป็นการรับรองตัวเองโดยสมบูรณ์ — นี่คือเหตุผลที่ acceptance test ต้องอยู่ใน CODEOWNERS ของมนุษย์เสมอ

## ระดับ
### Foundation
- เขียน test ตามกรณีที่ระบุใน AC ได้
- เข้าใจ test pyramid

### Proficient
- ออกแบบ test case จากเทคนิคที่เป็นระบบ (equivalence partitioning, boundary value, decision table)
- เลือกระดับทดสอบที่คุ้มค่า ไม่ทดสอบทุกอย่างที่ระดับ E2E
- ออกแบบ test ที่ล้มเหลวแล้วบอกได้ทันทีว่าอะไรพัง

### Expert
- ออกแบบชุดทดสอบที่จับ bug ประเภทที่ไม่ได้คิดถึงได้
- ประเมินคุณภาพของ test suite เอง (mutation testing, ไม่ใช่แค่ coverage)
- ตัดสินได้ว่าส่วนไหนไม่คุ้มที่จะทดสอบ

## วิธีประเมิน
ให้ฟังก์ชันคำนวณส่วนลดที่มีเงื่อนไขซ้อนกัน 4 ชั้น แล้วให้ออกแบบ test case
- เขียนตามตัวอย่างใน spec = Foundation
- ใช้ boundary value และ decision table ครอบคลุมทุกสาขา = Proficient
- เพิ่ม property test และระบุว่าอะไรที่ example test จับไม่ได้ = Expert

ทดสอบเพิ่ม: ให้ mutation testing รันบน test suite ที่เขาเขียน — mutation score บอกความจริงมากกว่า coverage

## เส้นทางพัฒนา
1. เรียนเทคนิคออกแบบ test case อย่างเป็นระบบ ไม่ใช่เขียนตามสัญชาตญาณ
2. รัน mutation testing บน test suite ปัจจุบัน แล้วดูว่ามี mutant รอดกี่ตัว
3. ทุกครั้งที่ bug หลุดถึง production ให้ถามว่า "test แบบไหนที่จะจับได้" แล้วเพิ่มเข้าไป
4. ฝึกเขียน test ก่อนโค้ดสำหรับ logic ที่ซับซ้อน

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียน unit test จำนวนมาก, สร้าง test data, แปลง test case เป็นโค้ด
- **Agent ทำแทนไม่ได้:** **ออกแบบ acceptance test และ contract test** — เพราะมันคือนิยามว่า "ถูก" คืออะไร ถ้า agent เขียนเอง มันจะ optimize ให้ test ผ่าน ไม่ใช่ให้ระบบถูก

## สัญญาณว่าทีมขาดทักษะนี้
- Coverage สูงแต่ bug ยังหลุดเยอะ
- Test ที่ล้มแล้วไม่มีใครรู้ว่าอะไรพัง
- Test ทั้งหมดทดสอบ happy path
