---
id: SKILL-TEST-002
name: Property-Based Thinking
category: testing
phases: [2, 4]
roles: [qa, sdet, backend-engineer, architect]
required_level: proficient
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-SPEC-002, SKILL-TEST-001]
review_by: 2027-01-31
---

# Property-Based Thinking

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-002 — Invariant Identification](skill-spec-002-invariant-identification.md) · [SKILL-TEST-001 — Test Design](skill-test-001-test-design.md)

## นิยาม
ความสามารถในการคิดเป็น **คุณสมบัติที่ต้องจริงสำหรับ input ทุกตัว** แทนที่จะคิดเป็นตัวอย่างทีละกรณี

## ทำไมสำคัญตอนนี้
Example-based test ทดสอบเฉพาะกรณีที่คนเขียนคิดถึง — ซึ่งเป็นเซตเดียวกับที่ agent คิดถึงตอนเขียนโค้ด ผลคือ test ผ่านครบแต่ระบบยังผิดในกรณีที่ไม่มีใครนึกออก property test เป็นเครื่องมือเดียวที่หลุดออกจากกับดักนี้ได้

## ระดับ
### Foundation
- เข้าใจความต่างระหว่าง example test กับ property test

### Proficient
- ระบุ property ที่ตรวจได้ เช่น round-trip (encode แล้ว decode ได้ค่าเดิม), idempotency, commutativity, invariant หลังทำงาน
- เขียน property test ด้วย library ที่ทีมใช้ (proptest, QuickCheck, Hypothesis, jqwik)
- ออกแบบ generator ที่สร้าง input ที่มีความหมาย

### Expert
- หา property ในโดเมนที่ไม่ชัดเจนว่ามี property อะไร
- ใช้ shrinking เพื่อลดกรณีที่ล้มให้เหลือตัวอย่างเล็กที่สุด แล้วตีความ
- ใช้ property test ตรวจ concurrency และ state machine

## วิธีประเมิน
ให้ฟังก์ชัน `merge_orders(a, b)` แล้วถามว่า property มีอะไรบ้าง
- ตอบเป็นตัวอย่าง input/output = Foundation
- ตอบว่า "merge(a,b) = merge(b,a)" และ "merge(a, empty) = a" = Proficient
- เพิ่ม "ผลรวมของ item หลัง merge = ผลรวมก่อน merge" และเห็น property ที่เกี่ยวกับ invariant ทางธุรกิจ = Expert

## เส้นทางพัฒนา
1. หยิบฟังก์ชันบริสุทธิ์ในระบบ 5 ตัว เขียน property ให้ได้ตัวละ 3 ข้อ
2. ฝึกมองหา property มาตรฐาน: round-trip, idempotent, invariant, oracle (เทียบกับ implementation ที่ช้าแต่ถูกแน่)
3. ใช้ property test กับ business logic ที่แตะเงินก่อนเป็นอันดับแรก
4. อ่านตัวอย่าง property test ของ library ที่ใช้ในโปรเจกต์จริง

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียน property test เมื่อบอก property ให้แล้ว, สร้าง generator, ปรับ shrinking
- **Agent ทำแทนไม่ได้:** ระบุว่า property คืออะไร — เป็นความรู้ domain ไม่ใช่ pattern

## สัญญาณว่าทีมขาดทักษะนี้
- Test ทั้ง repo เป็น example-based ทั้งหมด
- Bug ที่พบบ่อยคือ "ลืมคิดถึงกรณีนี้"
