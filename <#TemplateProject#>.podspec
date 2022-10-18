Pod::Spec.new do |s|

  s.name         = "<#TemplateProject#>"
  s.version      = "0.1.0"
  s.summary      = "<#Summary#>"
  s.description  = <<-DESC
                   <#Description#>
                   DESC

  s.homepage     = "https://github.com/<#TemplateUsername#>/<#TemplateProject#>"
  s.license      = "MIT"
  s.author       = { "<#TemplateName#>" => "<#TemplateEmail#>" }
  s.source       = { :git => "https://github.com/<#TemplateUsername#>/<#TemplateProject#>.git", :tag => s.version.to_s }

  s.ios.deployment_target     = '11.0'
  s.macos.deployment_target   = '10.10'
  s.tvos.deployment_target    = '11.0'
  s.watchos.deployment_target = '4.0'

  s.source_files      = 'Sources/<#TemplateProject#>/*.swift'
  s.swift_versions    = ['5.0']
  s.cocoapods_version = '>= 1.7.3'

end
