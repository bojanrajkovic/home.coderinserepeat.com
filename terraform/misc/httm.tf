resource "system_folder" "trusted_gpg_d" {
  path  = "/etc/apt/trusted.gpg.d"
  user  = "root"
  group = "root"
}

resource "system_file" "httm_gpg_key" {
  path   = "/etc/apt/trusted.gpg.d/kimono-koans.gpg"
  source = "./kimono-koans.gpg.key"
  user   = "root"
  group  = "root"
}

resource "system_file" "httm_sources_list" {
  path   = "/etc/apt/sources.list.d/kimono-koans.sources"
  source = "https://raw.githubusercontent.com/kimono-koans/ppa/main/kimono-koans.list"
}

resource "system_packages_apt" "uuid-runtime" {
  package {
    name = "uuid-runtime"
  }
}

resource "system_packages_apt" "httm" {
  package {
    name = "httm"
  }
}
