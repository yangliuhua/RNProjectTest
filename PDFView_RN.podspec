
Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "PDFView_RN"
  spec.version      = "0.0.1"
  spec.summary      = "React Native PDF Library by PSPDFKit."
  spec.description  = <<-DESC
   A high-performance viewer, extensive annotation and document editing tools, and more.
                   DESC

  spec.homepage     = "https://www.compdf.com"
  spec.license      = "MIT"
  spec.author             = { "yangliuhua" => "yangliuhua@kdanmobile.com" }
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/yangliuhua/RNProjectTest.git"}
  spec.source_files  = "ios/*.{xcodeproj,h,m}, ios/PDFView_RN/*.{h,m,mm}"
  spec.framework  = "UIKit"
  spec.requires_arc = true
  spec.dependency "React"
  spec.dependency "ComPDFKit"
  spec.dependency "Instant"

end
