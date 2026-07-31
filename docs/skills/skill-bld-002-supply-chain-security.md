---
id: SKILL-BLD-002
name: Supply Chain Security
category: build
phases: [5]
roles: [devops, security-engineer, platform-engineer]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-ARCH-004, SKILL-BLD-001]
review_by: 2027-01-31
---

# Supply Chain Security

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-004 — Threat Modeling](skill-arch-004-threat-modeling.md) · [SKILL-BLD-001 — CI/CD Engineering](skill-bld-001-cicd-engineering.md)

## นิยาม
ความสามารถในการควบคุมและตรวจสอบทุกอย่างที่เข้ามาอยู่ใน artifact สุดท้าย — dependency, base image, build tool — และพิสูจน์ได้ว่าสิ่งที่ deploy คือสิ่งที่ตั้งใจสร้าง

## ทำไมสำคัญตอนนี้
Agent เพิ่ม dependency ได้เร็วกว่าที่มนุษย์ตรวจทัน และมักเสนอ package ใหม่ทุกครั้งที่เจอปัญหา ทำให้ attack surface โตเร็วกว่ายุคก่อนมาก SBOM เปลี่ยนจากเอกสาร compliance เป็นเครื่องมือปฏิบัติการที่ตอบได้ภายในไม่กี่นาทีว่า "เรามีเวอร์ชันที่มีช่องโหว่อยู่ตรงไหนบ้าง"

## ระดับ
### Foundation
- รัน dependency scanner และเข้าใจผลลัพธ์
- อัปเดต dependency ที่มี CVE ได้

### Proficient
- สร้างและใช้ SBOM ใน pipeline
- ตั้ง policy ว่า severity ระดับไหนบล็อก build
- ใช้ lockfile และ pin เวอร์ชันอย่างถูกต้อง

### Expert
- เซ็นและ verify artifact (cosign, SLSA provenance)
- ประเมินความเสี่ยงของ dependency ก่อนรับเข้า (maintainer, ความถี่การอัปเดต, จำนวน transitive dep)
- ออกแบบกระบวนการตอบสนองเมื่อพบ CVE ระดับวิกฤตใน dependency ที่ใช้ทั่วระบบ

## วิธีประเมิน
ถาม: "ถ้าพรุ่งนี้มี CVE ระดับ 10 ใน library ที่ใช้กันทั่วไป เราจะรู้ภายในกี่นาทีว่าระบบไหนของเราได้รับผลกระทบ และแก้ได้ภายในเท่าไหร่"
ตอบไม่ได้ = ยังไม่มี SBOM ที่ใช้งานจริง

## เส้นทางพัฒนา
1. สร้าง SBOM ของโปรเจกต์ปัจจุบันด้วย syft แล้วดูว่ามี dependency กี่ตัวจริงๆ
2. ตั้ง gate ที่บล็อก CVE ระดับ Critical ใน CI
3. ทำ policy ว่าการเพิ่ม dependency ใหม่ต้องมีเหตุผลบันทึกไว้ (Gemfile/package.json เป็น Tier C)
4. ทดลองเซ็น artifact ด้วย cosign และ verify ก่อน deploy

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** สร้าง SBOM, สรุป CVE, เสนอเวอร์ชันที่ปลอดภัย, ตั้งค่า scanner
- **Agent ทำแทนไม่ได้:** ตัดสินว่าจะรับ dependency ตัวใหม่หรือไม่ — และ agent เองคือแหล่งที่มาของ dependency ใหม่ที่ต้องถูกควบคุม

## สัญญาณว่าทีมขาดทักษะนี้
- ไม่มีใครรู้ว่ามี dependency กี่ตัว
- Lockfile ไม่ถูก commit
- ตอบไม่ได้ว่า artifact ที่ deploy สร้างจาก commit ไหน
