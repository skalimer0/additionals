# frozen_string_literal: true

module Additionals
  MAX_CUSTOM_MENU_ITEMS = 5
  SELECT2_INIT_ENTRIES = 20
  DEFAULT_MODAL_WIDTH = '350px'
  GOTO_LIST = " \xc2\xbb"
  LIST_SEPARATOR = "#{GOTO_LIST} "

  class << self
    def setup
      RenderAsync.configuration.jquery = true

      loader = AdditionalsLoader.new

      loader.incompatible? %w[redmine_editauthor
                              redmine_changeauthor
                              redmine_auto_watch]

      loader.add_patch %w[ApplicationController
                          AutoCompletesController
                          Issue
                          IssuePriority
                          TimeEntry
                          Project
                          Wiki
                          ProjectsController
                          WelcomeController
                          ReportsController
                          Principal
                          Query
                          QueryFilter
                          Role
                          User
                          UserPreference]

      loader.add_helper %w[Issues
                           Settings
                           Wiki
                           CustomFields]

      loader.add_global_helper [Additionals::Helpers,
                                AdditionalsFontawesomeHelper,
                                AdditionalsMenuHelper,
                                AdditionalsSelect2Helper]

      Redmine::WikiFormatting.format_names.each do |format|
        case format
        when 'markdown'
          loader.add_patch [{ target: Redmine::WikiFormatting::Markdown::HTML, patch: 'FormatterMarkdown' },
                            { target: Redmine::WikiFormatting::Markdown::Helper, patch: 'FormattingHelper' }]
        when 'textile'
          loader.add_patch [{ target: Redmine::WikiFormatting::Textile::Formatter, patch: 'FormatterTextile' },
                            { target: Redmine::WikiFormatting::Textile::Helper, patch: 'FormattingHelper' }]
        end
      end

      # Apply patches and helper
      loader.apply!

      # Macros
      loader.load_macros!

      # Hooks
      loader.load_hooks!
    end

    # support with default setting as fall back
    def setting(value)
      if settings.key? value
        settings[value]
      else
        AdditionalsLoader.default_settings[value]
      end
    end

    def setting?(value)
      true? setting(value)
    end

    def true?(value)
      return false if value.is_a? FalseClass
      return true if value.is_a?(TrueClass) || value.to_i == 1 || value.to_s.casecmp('true').zero?

      false
    end

    # false if false or nil
    def false?(value)
      !true?(value)
    end

    def debug(message = 'running')
      return if Rails.env.production?

      msg = message.is_a?(String) ? message : message.inspect
      Rails.logger.debug { "#{Time.current.strftime '%H:%M:%S'} DEBUG [#{caller_locations(1..1).first.label}]: #{msg}" }
    end

    def class_prefix(klass)
      klass_name = klass.is_a?(String) ? klass : klass.name
      klass_name.underscore.tr '/', '_'
    end

    def now_with_user_time_zone(user = User.current)
      if user.time_zone.nil?
        Time.zone.now
      else
        user.time_zone.now
      end
    end

    def time_zone_correct(time, user: User.current)
      timezone = user.time_zone || Time.zone
      timezone.utc_offset - Time.zone.local_to_utc(time).localtime.utc_offset
    end

    def hash_remove_with_default(field, options, default = nil)
      value = nil
      if options.key? field
        value = options[field]
        options.delete field
      elsif !default.nil?
        value = default
      end
      [value, options]
    end

    def split_ids(phrase, limit: nil)
      limit ||= Setting.per_page_options_array.first || 25
      raw_ids = phrase.split(',').map(&:strip)
      ids = []
      raw_ids.each do |id|
        if id.include? '-'
          range = id.split('-').map(&:strip)
          if range.size == 2
            left_id = range.first.to_i
            right_id = range.last.to_i
            min = [left_id, right_id].min
            max = [left_id, right_id].max
            # if range to large, take lowest numbers + last possible number
            ids << if max - min > limit
                     old_max = max
                     max = limit + min - 2
                     ids << (min..max).to_a
                     old_max
                   else
                     (min..max).to_a
                   end
          end
        else
          ids << id.to_i
        end
      end
      ids.flatten!
      ids.uniq!
      ids.take limit
    end

    private

    def settings
      Setting[:plugin_additionals]
    end
  end

  # Run the classic redmine plugin initializer after rails boot
  class Plugin < ::Rails::Engine
    require 'deface'
    require 'emoji'
    require 'render_async'
    require 'rss'
    require 'slim'

    config.after_initialize do
      # engine_name could be used (additionals_plugin), but can
      # create some side effencts
      plugin_id = 'additionals'

      # if plugin is already in plugins directory, use this and leave here
      next if Redmine::Plugin.installed? plugin_id

      # gem is used as redmine plugin
      require File.expand_path '../init', __dir__
      AdditionalTags.setup
      Additionals::Gemify.install_assets plugin_id
      Additionals::Gemify.create_plugin_hint plugin_id
    end
  end
end
