---
id: SKILL-TEST-003
name: Test Data Management
category: testing
phases: [4]
roles: [qa, sdet, backend-engineer, data-engineer]
required_level: proficient
agent_delegable: true
agent_trend: rising
related: [SKILL-TEST-001, SKILL-ARCH-004]
review_by: 2027-01-31
---

# Test Data Management

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-TEST-001 — Test Design](skill-test-001-test-design.md) · [SKILL-ARCH-004 — Threat Modeling](skill-arch-004-threat-modeling.md)

## นิยาม
ความสามารถในการจัดหาและจัดการข้อมูลสำหรับทดสอบที่ **สมจริงพอที่จะเชื่อถือได้** และ **deterministic พอที่จะทำซ้ำได้** โดยไม่ละเมิดความเป็นส่วนตัว

## ทำไมสำคัญตอนนี้
Agent รัน test suite ซ้ำหลายรอบใน self-verify loop ถ้าข้อมูลทดสอบไม่ deterministic จะเกิด flaky test ซึ่งทำให้ agent วนแก้โค้ดที่ไม่ได้ผิด และเผาทั้งเวลาและงบประมาณไปเรื่อยๆ

## ระดับ
### Foundation
- ใช้ factory/fixture ที่มีอยู่ได้
- สร้างข้อมูลทดสอบสำหรับกรณีง่ายๆ

### Proficient
- ออกแบบ factory ที่ประกอบกันได้และ deterministic (fixed seed)
- แยกข้อมูลระหว่าง test ไม่ให้รั่วถึงกัน
- จัดการ data สำหรับ integration test ที่ต้องใช้ DB จริง

### Expert
- ออกแบบกลยุทธ์ข้อมูลสำหรับทั้งระบบ รวมถึงการ anonymize ข้อมูลจริง
- จัดการข้อมูลสำหรับทดสอบ migration และ backward compatibility
- ทำให้ test suite รันขนานได้โดยไม่ชนกัน

## วิธีประเมิน
ถาม: "test ตัวนี้ผ่านตอนรันเดี่ยว แต่ล้มตอนรันทั้ง suite เพราะอะไรได้บ้าง"
คำตอบที่ดีจะพูดถึง: shared state, ลำดับการรัน, ข้อมูลที่ไม่ถูกล้าง, เวลา/random ที่ไม่ถูก freeze, autoincrement id ที่ถูก assume

## เส้นทางพัฒนา
1. ตรวจ test suite ปัจจุบันหา test ที่พึ่งพาลำดับการรัน
2. Freeze เวลาและ random seed ในทุก test
3. ทำให้ suite รันขนานได้ แล้วดูว่าอะไรพัง — สิ่งที่พังคือ shared state ที่ซ่อนอยู่
4. ตั้ง policy ว่าห้ามใช้ข้อมูล production ที่มี PII แม้ mask แล้ว

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** สร้าง factory, generate ข้อมูลสังเคราะห์, หา test ที่พึ่งพา shared state
- **Agent ทำแทนไม่ได้:** ตัดสินว่าข้อมูลแบบไหนสมจริงพอ, นโยบายเรื่อง PII

## สัญญาณว่าทีมขาดทักษะนี้
- Test flaky ที่แก้ด้วยการ retry
- ต้องรัน test เรียงลำดับเท่านั้นถึงจะผ่าน
- ข้อมูลจาก production ถูก copy มาใช้ทดสอบ
