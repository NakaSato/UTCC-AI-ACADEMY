module ApplicationHelper
  # Anchors point at landing-page sections until real pages/models exist.
  def nav_links
    {
      "เรียนรู้ AI" => "#learn",
      "เส้นทางการเรียน" => "#tracks",
      "ชุมชน" => "#community",
      "กิจกรรม" => "#events",
      "คำถามที่พบบ่อย" => "#faq"
    }
  end

  def footer_columns
    {
      "เริ่มต้นที่นี่" => {
        "AI คืออะไร" => "#learn",
        "เส้นทางการเรียน" => "#tracks",
        "คำถามที่พบบ่อย" => "#faq"
      },
      "ชุมชน" => {
        "ผลงานนักศึกษา" => "#community",
        "แชร์โปรเจกต์" => "#community",
        "กิจกรรมและเวิร์กชอป" => "#events"
      },
      "มหาวิทยาลัย" => {
        "คณะวิศวกรรมศาสตร์" => "https://eng.utcc.ac.th",
        "UTCC" => "https://utcc.ac.th",
        "สมัครเรียน" => "https://admissions.utcc.ac.th/loginUTCC"
      }
    }
  end
end
