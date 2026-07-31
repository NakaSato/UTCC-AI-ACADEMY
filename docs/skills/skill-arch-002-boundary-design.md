---
id: SKILL-ARCH-002
name: Boundary & Module Design
category: architecture
phases: [1, 3]
roles: [architect, tech-lead]
required_level: expert
agent_delegable: false
agent_trend: rising-critical
related: [SKILL-ARCH-001, SKILL-ARCH-003, SKILL-CODE-002]
review_by: 2027-01-31
---

# Boundary & Module Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-001 — Trade-off Analysis](skill-arch-001-tradeoff-analysis.md) · [SKILL-ARCH-003 — Data Modeling](skill-arch-003-data-modeling.md) · [SKILL-CODE-002 — API Design](skill-code-002-api-design.md)

## นิยาม
ความสามารถในการแบ่งระบบเป็นส่วนที่มีขอบเขตชัด เปลี่ยนแปลงแยกกันได้ และบังคับขอบเขตนั้นด้วยเครื่องมือ ไม่ใช่ด้วยข้อตกลง

## ทำไมสำคัญตอนนี้
นี่คือทักษะที่ค่าขึ้นเร็วที่สุดในกลุ่ม architecture — เพราะ agent ทำงานได้ดีมากในขอบเขตที่แคบและ interface ชัด แต่จะแพร่ pattern ผิดไปทั้ง repo ภายในวันเดียวถ้าขอบเขตหลวม ต้นทุนของ boundary ที่ออกแบบผิดแพงกว่ายุคก่อนหลายเท่า

## ระดับ
### Foundation
- ทำงานภายในโครงสร้างที่มีอยู่ได้โดยไม่ทำลายมัน
- รู้ว่า layer แต่ละชั้นควรทำอะไร

### Proficient
- แบ่ง module ตาม domain ไม่ใช่ตามชนิดทางเทคนิค
- ออกแบบ public interface ที่ซ่อนรายละเอียดภายในได้จริง
- ตั้ง fitness function (ArchUnit / NetArchTest / Packwerk) ให้บังคับขอบเขต

### Expert
- มองเห็นว่าขอบเขตควรอยู่ตรงไหนจากรูปแบบการเปลี่ยนแปลงในอดีต ไม่ใช่จากทฤษฎี
- ตัดสินใจได้ว่าเมื่อไหร่ควรรวม module และเมื่อไหร่ควรแยก
- ออกแบบทางย้ายจากโครงสร้างเดิมโดยไม่ต้องหยุดพัฒนา

## วิธีประเมิน
ให้ codebase จริงแล้วถาม: "ถ้าเราต้องเปลี่ยนวิธีคิดค่าธรรมเนียม ต้องแตะกี่ไฟล์และกี่ module"
คนที่ตอบได้ทันทีและตอบว่า "หนึ่ง module" = ระบบมีขอบเขตดีและเขาเข้าใจมัน
คนที่ต้องไปไล่ดูก่อน = ขอบเขตหลวมหรือเขายังไม่เห็นภาพ

## เส้นทางพัฒนา
1. ตั้ง fitness function หนึ่งข้อในโปรเจกต์ปัจจุบัน แล้วดูว่ามี violation กี่จุด
2. วิเคราะห์ git log: ไฟล์ไหนที่มักถูกแก้พร้อมกันเสมอ — นั่นคือขอบเขตที่แท้จริง ไม่ใช่ที่วาดไว้
3. อ่านเรื่อง Domain-Driven Design โดยเน้น bounded context ไม่ใช่ tactical pattern
4. ฝึกเขียน `package.yml` / module descriptor พร้อมเหตุผลของแต่ละ dependency

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ตรวจหา violation, refactor ให้เข้าขอบเขตที่กำหนดแล้ว, สร้าง adapter
- **Agent ทำแทนไม่ได้:** ตัดสินว่าขอบเขตควรอยู่ตรงไหน — เพราะต้องรู้ว่าธุรกิจจะเปลี่ยนไปทางไหน

## สัญญาณว่าทีมขาดทักษะนี้
- เปลี่ยนอะไรนิดเดียวต้องแก้ 15 ไฟล์ข้าม 5 module
- ไม่มี fitness function ใดๆ ในโปรเจกต์
- โครงสร้างโฟลเดอร์แบ่งตามชนิด (controllers/, services/, models/) ในระบบที่ใหญ่แล้ว
