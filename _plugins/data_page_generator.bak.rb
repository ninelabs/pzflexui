# Generate pages from individual records in yml files
# (c) 2014-2016 Adolfo Villafiorita
# Distributed under the conditions of the MIT License

module Jekyll

  module Sanitizer
    # strip characters and whitespace to create valid filenames, also lowercase
    def sanitize_filename(name)
      if(name.is_a? Integer)
        return name.to_s
      end
      return name.tr(
  "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÑñÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
  "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
).downcase.strip.gsub(' ', '-').gsub(/[^\w.-]/, '')
    end
  end

  # this class is used to tell Jekyll to generate a page
  class DataPage < Page
    include Sanitizer

    # - site and base are copied from other plugins: to be honest, I am not sure what they do
    #
    # - `index_files` specifies if we want to generate named folders (true) or not (false)
    # - `dir` is the default output directory
    # - `data` is the data defined in `_data.yml` of the record for which we are generating a page
    # - `name` is the key in `data` which determines the output filename
    # - `template` is the name of the template for generating the page
    # - `extension` is the extension for the generated file
    def initialize(site, base, index_files, dir, data, name, template, extension)
      @site = site
      @base = base

      # @dir is the directory where we want to output the page
      # @name is the name of the page to generate
      #
      # the value of these variables changes according to whether we
      # want to generate named folders or not
      filename = sanitize_filename(data[name]).to_s
      if index_files
        @dir = dir + (index_files ? "/" + filename + "/" : "")
        @name =  "index" + "." + extension.to_s
      else
        @dir = dir
        @name = filename + "." + extension.to_s
      end

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), template + ".html")
      self.data['title'] = data[name]
      # add all the information defined in _data for the current record to the
      # current page (so that we can access it with liquid tags)
      self.data.merge!(data)
    end
  end

  class DataPagesGenerator < Generator
    safe true

    def generate(site)
      data = site.config['page_gen']
      if data
        data.each do |data_spec|
          # todo: check input data correctness
          img_source = data_spec['source']
          template = data_spec['template'] || data_spec['data']
          name = data_spec['name']
          dir = data_spec['dir'] || data_spec['data']

          if site.layouts.key? template
            #records =  site.data[data_spec['data']]
            records = site.static_files
            if records.path contains 'images/prototype'
              records.each do |record|
                site.pages << DataPage.new(site, site.source, dir, record, name, template)
              end
            end
          else
            puts "error. could not find #{data_file}" if not File.exists?(data_file)
            puts "error. could not find template #{template}" if not site.layouts.key? template
          end
        end
      end
    end
  end

  module DataPageLinkGenerator
    include Sanitizer

    # use it like this: {{input | datapage_url: dir}}
    # to generate a link to a data_page.
    #
    # the filter is smart enough to generate different link styles
    # according to the data_page-dirs directive ...
    #
    # ... however, the filter is not smart enough to support different
    # extensions for filenames.
    #
    # Thus, if you use the `extension` feature of this plugin, you
    # need to generate the links by hand
    def datapage_url(input, dir)
      @gen_dir = Jekyll.configuration({})['page_gen-dirs']
      if @gen_dir then
        dir + "/" + sanitize_filename(input) + "/index.html"
      else
        dir + "/" + sanitize_filename(input) + ".html"
      end
    end
  end

end

Liquid::Template.register_filter(Jekyll::DataPageLinkGenerator)
