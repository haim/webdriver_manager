module WebDriverManager
  module Support
    def provision
      remove_binary
      # puts driver_binary_list
      # puts latest_binary
      # puts driver_is_downloaded?
      # puts driver_download_url(nil)
      # puts driver_binary
      provision_driver
    end

    def provision_driver(version = nil)
      url, filename = driver_filename(version)
      Dir.mkdir(driver_repo) unless File.exist?(driver_repo)

      Dir.chdir(driver_repo) do
        download_driver(filename, url)
      end
    end

    def remove_binary
      WebDriverManager.logger.debug("Deleting #{driver_binary}")
      FileUtils.rm_f(driver_binary)
    end

    def latest_binary
      driver_binary_list.keys.sort.last
    end

    protected

    def get(url)
      response = Net::HTTP.get_response(URI(url))

      case response
        when Net::HTTPSuccess then response.body
      end
    end

    private

    def download_driver(filename, url)
      FileUtils.rm_f(filename)

      open(filename, "wb") do |file|
        file.print(get(url))
      end

      raise "Unable to download #{url}" unless File.exist?(filename)
      WebDriverManager.logger.debug("Successfully downloaded #{filename}")
    end

    def driver_filename(version)
      # URL: http://chromedriver.storage.googleapis.com/2.33/chromedriver_mac64.zip
      # Filename: chromedriver_mac64.zip
      url = driver_download_url(version)
      filename = File.basename(url)
      [url, filename]
    end

    def driver_url_is_reachable?
      get(driver_base_url)
      WebDriverManager.logger.debug("Driver URL Available: #{driver_base_url}")
      true
    rescue StandardError
      WebDriverManager.logger.debug(
        "Driver URL Not Available: #{driver_base_url}"
      )
      false
    end

    def driver_is_downloaded?
      result = File.exist?(driver_binary)
      WebDriverManager.logger.debug("Driver Already Downloaded: #{result}")
      result
    end

    def driver_download_url(version)
      driver_binary_list[version || latest_binary]
    end

    # This method gets the full driver binary, by getting the driver
    # repository, which it determines from this module, coupled with the
    # name of the driver, which is gathered from the driver-specific class.
    def driver_binary
      File.join(driver_repo, driver_name)
    end

    def driver_repo
      File.expand_path(File.join(ENV['HOME'], ".webdrivers")).tap do |dir|
        FileUtils.mkdir_p(dir)
      end
    end

    def os_platform
      cfg = RbConfig::CONFIG
      case cfg['host_os']
        when /linux/
          cfg['host_cpu'] =~ /x86_64|amd64/ ? "linux64" : "linux32"
        when /darwin/
          "mac"
        else
          "win"
      end
    end
  end
end
