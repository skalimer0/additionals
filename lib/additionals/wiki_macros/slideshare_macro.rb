# frozen_string_literal: true

module Additionals
  module WikiMacros
    module SlideshareMacro
      Redmine::WikiFormatting::Macros.register do
        desc <<-DESCRIPTION
    Slideshare macro to include Slideshare slide.

    Syntax:

      {{slideshare(<key> [, width=595, height=485, slide=SLIDE])}}

    Parameters:

      :param string key: Slideshare embedded key code, e.g. 57941706. This is the part is the last number in url: http://de.slideshare.net/AnimeshSingh/caps-whats-best-for-deploying-and-managing-openstack-chef-vs-ansible-vs-puppet-vs-salt-57941706
      :param int width: width
      :param int height: height
      :param int slide: Slide page

    Examples:

      {{slideshare(57941706)}} show slideshare slide with default size 595x485
      {{slideshare(57941706, width=514, height=422)}} show slide with user defined size
      {{slideshare(57941706, slide=5)}} start with slide (page) 5
        DESCRIPTION

        macro :slideshare do |_obj, args|
          args, options = extract_macro_options args, :width, :height, :slide

          width = options[:width].presence || 595
          height = options[:height].presence || 485
          slide = options[:slide].present? ? options[:slide].to_i : 0

          raise 'The correct usage is {{slideshare(<key>[, width=x, height=y, slide=number])}}' if args.empty?

          v = args[0]
          src = "//www.slideshare.net/slideshow/embed_code/#{v}"
          src += "?startSlide=#{slide}" if slide.positive?

          tag.iframe width:, height:, src:, frameborder: 0, allowfullscreen: 'true'
        end
      end
    end
  end
end
