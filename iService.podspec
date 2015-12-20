Pod::Spec.new do |s|

  s.name         = "iService"
  s.version      = "0.0.2"
  s.summary      = "Communication with RESTful interfaces made easy"

s.description  = <<-DESC
    iService provides two classes that simplify communication with RESTful APIs.
    Service provides a CRUD (Create, Retrieve, Update, Destroy) interface, ServiceRealm
    is a container for shared configuration.
                   DESC

  s.homepage     = "https://github.com/theddnc/iService"
  s.license      = { :type => "MIT", :file => "LICENCE" }

  s.author             = { "Jakub Zaczek" => "zaczekjakub@gmail.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/theddnc/iService.git", :tag => "0.0.2"}

  s.source_files  = "iService/*"

  s.dependency "iPromise", "~> 1.1"

end
