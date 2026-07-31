---
id: SKILL-CODE-002
name: API Design
category: coding
phases: [1, 3]
roles: [backend-engineer, architect, frontend-engineer]
required_level: proficient
agent_delegable: assisted
agent_trend: stable
related: [SKILL-ARCH-002, SKILL-TEST-004]
review_by: 2027-01-31
---

# API Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-002 — Boundary & Module Design](skill-arch-002-boundary-design.md) · [SKILL-TEST-004 — Contract Testing](skill-test-004-contract-testing.md)

## นิยาม
ความสามารถในการออกแบบ interface ที่ใช้ง่าย ใช้ผิดยาก และเปลี่ยนแปลงได้โดยไม่ทำลายผู้ใช้เดิม — ทั้ง API ภายนอกและ interface ระหว่าง module ภายใน

## ทำไมสำคัญตอนนี้
คงเดิมในแง่ความสำคัญ แต่บริบทเปลี่ยน: เมื่อ agent เขียนโค้ดที่เรียก API เหล่านี้ interface ที่ใช้ผิดง่ายจะถูกใช้ผิดในหลายที่พร้อมกันภายในวันเดียว แทนที่จะค่อยๆ ผิดทีละจุด

## ระดับ
### Foundation
- ทำตาม convention ของ REST/gRPC ที่ทีมใช้อยู่ได้
- ตั้งชื่อ endpoint และ field ได้สื่อความหมาย

### Proficient
- ออกแบบให้ "ใช้ผิดยาก" — type ที่บังคับความถูกต้อง, ค่า default ที่ปลอดภัย
- จัดการ versioning และ backward compatibility ได้
- ออกแบบ error response ที่ผู้เรียกจัดการต่อได้จริง

### Expert
- ออกแบบ API ที่สะท้อน domain ไม่ใช่สะท้อนโครงสร้างตาราง
- คาดการณ์ทิศทางการเปลี่ยนแปลงแล้วเผื่อไว้โดยไม่ over-engineer
- จัดการ idempotency, pagination, partial failure อย่างถูกต้อง

## วิธีประเมิน
ให้ออกแบบ endpoint สำหรับ "ยกเลิก order" แล้วดูว่าเขาพูดถึง:
- idempotency key หรือไม่
- จะเกิดอะไรถ้าเรียกซ้ำ / เรียกพร้อมกันสองครั้ง
- error case แยกกี่แบบ และผู้เรียกจะแยกแยะได้อย่างไร

ไม่พูดถึง idempotency เลย = ยังไม่ถึง Proficient สำหรับงานที่แตะเงิน

## เส้นทางพัฒนา
1. อ่าน API ของบริการที่ออกแบบดี (Stripe, GitHub) และสังเกตวิธีจัดการ error กับ versioning
2. ฝึกเขียน OpenAPI spec ก่อนเขียน implementation
3. ทดลองใช้ API ของตัวเองในฐานะ client ภายนอกจริงๆ
4. ทบทวน breaking change ที่เคยทำ — เกิดจากการออกแบบพลาดตรงไหน

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** สร้าง OpenAPI จากโค้ด, generate client, เขียน handler ตาม contract
- **Agent ทำแทนไม่ได้:** ตัดสินว่า resource ควรแบ่งอย่างไรตาม domain

## สัญญาณว่าทีมขาดทักษะนี้
- Breaking change บ่อย
- ทุก error ตอบ 500 หรือ 400 เหมือนกันหมด
- Client ทุกตัวต้องเขียน workaround เดียวกัน
