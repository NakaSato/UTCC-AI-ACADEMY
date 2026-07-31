---
id: SKILL-BLD-001
name: CI/CD Engineering
category: build
phases: [5]
roles: [devops, platform-engineer, tech-lead]
required_level: proficient
agent_delegable: assisted
agent_trend: stable
related: [SKILL-BLD-002, SKILL-BLD-003]
review_by: 2027-01-31
---

# CI/CD Engineering

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-BLD-002 — Supply Chain Security](skill-bld-002-supply-chain-security.md) · [SKILL-BLD-003 — Release Risk Assessment](skill-bld-003-release-risk-assessment.md)

## นิยาม
ความสามารถในการสร้าง pipeline ที่ทำให้ทุกการเปลี่ยนแปลงถูกตรวจสอบและส่งมอบได้อย่างสม่ำเสมอ เร็วพอที่จะไม่มีใครอยากข้าม และเชื่อถือได้พอที่จะไม่มีใครสงสัยผลลัพธ์

## ทำไมสำคัญตอนนี้
บริบทเปลี่ยนไปข้อหนึ่งอย่างมีนัยสำคัญ: agent รัน pipeline ซ้ำหลายรอบต่อหนึ่งงาน ดังนั้น **ความเร็วของ CI เปลี่ยนจากเรื่องความสะดวก เป็นตัวคูณของต้นทุนโดยตรง** pipeline ที่ใช้เวลา 15 นาทีจะทำให้ agent iteration แพงขึ้นหลายเท่า

## ระดับ
### Foundation
- แก้ไข pipeline ที่มีอยู่ได้
- อ่าน log แล้วเข้าใจว่า step ไหนล้ม

### Proficient
- ออกแบบ pipeline ใหม่พร้อม caching, parallelization, และ fail-fast
- แยก stage ที่เร็วออกจากที่ช้าอย่างมีเหตุผล
- จัดการ secret ใน pipeline อย่างปลอดภัย

### Expert
- ทำ build ให้ reproducible จริง
- ออกแบบ pipeline ที่ scale ตามขนาดทีมโดยไม่ต้องรื้อ
- วัดและปรับปรุงเวลา CI อย่างเป็นระบบ

## วิธีประเมิน
ให้ pipeline ที่ใช้เวลา 20 นาที แล้วถามว่าจะลดเหลือ 5 นาทีอย่างไร
คำตอบที่ดี: แยก job ที่ขนานได้, cache dependency, รัน test เฉพาะที่กระทบ, ย้าย job ที่ช้าไปทำหลัง merge, ตรวจว่าอะไรคือคอขวดจริงก่อนแก้

## เส้นทางพัฒนา
1. วัดเวลาแต่ละ step ใน pipeline ปัจจุบัน แล้วหาคอขวดจริง
2. ทดลองทำ build ซ้ำสองครั้งแล้วเทียบ hash — reproducible หรือไม่
3. ตั้ง cache layer แล้ววัดว่าประหยัดจริงเท่าไหร่
4. ศึกษา pipeline ของโปรเจกต์ open source ขนาดใหญ่

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียน YAML config, เพิ่ม step, แก้ syntax, เสนอ cache strategy
- **Agent ทำแทนไม่ได้:** ตัดสินว่า gate ไหนควรบล็อกและไหนควรแค่เตือน — เป็นเรื่องของความเสี่ยงที่องค์กรยอมรับได้

## สัญญาณว่าทีมขาดทักษะนี้
- CI ใช้เวลาเกิน 10 นาทีและไม่มีใครพยายามแก้
- มีคน rerun job เพราะ "บางทีมันก็ผ่าน"
- Secret อยู่ใน environment variable ที่ log ออกมาได้
