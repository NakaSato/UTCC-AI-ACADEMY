---
id: SKILL-BLD-004
name: Database Operations
category: build
phases: [6]
roles: [backend-engineer, sre, dba, devops]
required_level: expert
agent_delegable: assisted
agent_trend: rising
related: [SKILL-ARCH-003, SKILL-BLD-003]
review_by: 2027-01-31
---

# Database Operations

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-003 — Data Modeling](skill-arch-003-data-modeling.md) · [SKILL-BLD-003 — Release Risk Assessment](skill-bld-003-release-risk-assessment.md)

## นิยาม
ความสามารถในการเปลี่ยนแปลง schema และข้อมูลบนระบบที่ทำงานอยู่จริง โดยไม่ทำให้เกิด downtime และไม่ทำข้อมูลเสียหาย

## ทำไมสำคัญตอนนี้
Migration เป็น **สิ่งเดียวในระบบส่วนใหญ่ที่ rollback ไม่ได้จริง** และเป็นสิ่งที่ agent เขียนได้เร็วมากแต่เขียนผิดบ่อย เช่น `add_index` โดยไม่ใช้ `concurrently` ซึ่งล็อกทั้งตารางบน production นี่คือเหตุผลที่ migration ควรเป็น Tier C โดยอัตโนมัติทุกครั้ง

## ระดับ
### Foundation
- เขียน migration พื้นฐานและรันบน dev ได้
- เข้าใจว่า index คืออะไร

### Proficient
- แยก schema change ออกจาก code change (expand → migrate → contract)
- ใช้ `concurrently` และเข้าใจว่า operation ไหนล็อกอะไร
- อ่าน explain plan และประเมินผลกระทบก่อนรัน

### Expert
- ทำ backfill ข้อมูลปริมาณมากแบบทยอยโดยไม่กระทบ production
- ประเมินผลของ migration บนตารางขนาดใหญ่จากข้อมูลจริง ไม่ใช่จาก dev
- ออกแบบ schema change ที่ deploy ได้แม้มีโค้ดสองเวอร์ชันทำงานพร้อมกัน

## วิธีประเมิน
ให้โจทย์: "ต้องเปลี่ยนชื่อคอลัมน์ `amount` เป็น `amount_cents` บนตารางที่มี 50 ล้านแถว และระบบห้ามหยุด"
- ตอบว่า `rename_column` = อันตราย ยังไม่ถึง Proficient
- ตอบเป็นหลายเฟส (เพิ่มคอลัมน์ใหม่ → เขียนสองที่ → backfill ทยอย → อ่านจากที่ใหม่ → ลบเก่าใน release ถัดไป) = Proficient ขึ้นไป
- ระบุด้วยว่าจะ backfill เป็น batch ขนาดเท่าไหร่และตรวจ replication lag = Expert

## เส้นทางพัฒนา
1. ติดตั้งเครื่องมือที่บล็อก migration อันตราย (strong_migrations หรือเทียบเท่า)
2. ทดลองรัน migration บน dataset ขนาดใกล้เคียง production
3. ฝึกอ่าน explain plan และทดลองว่า operation ไหนล็อกอะไรบ้าง
4. ศึกษา expand-migrate-contract pattern และทำจริงหนึ่งรอบเต็ม

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ร่าง migration, เขียน backfill script, สร้าง rollback migration
- **Agent ทำแทนไม่ได้:** ตัดสินว่า migration นี้ปลอดภัยบนข้อมูลจริง — ต้องมีมนุษย์อ่าน explain plan ทุกครั้ง

## สัญญาณว่าทีมขาดทักษะนี้
- เคยมี downtime จาก migration
- Migration ถูก deploy พร้อมกับ code change เสมอ
- ไม่มีใครรู้ขนาดของตารางที่กำลังจะแก้
