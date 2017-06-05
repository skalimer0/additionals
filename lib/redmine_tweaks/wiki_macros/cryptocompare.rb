# Redmine Tweaks plugin for Redmine
# Copyright (C) 2013-2017 AlphaNodes GmbH

# see https://www.cryptocompare.com/dev/widget/wizard/

module RedmineTweaks
  module WikiMacros
    Redmine::WikiFormatting::Macros.register do
      desc <<-EOHELP
      Create CryptoCompare information.
        {{cryptocompare(options)}}
     see https://www.cryptocompare.com/dev/widget/wizard/
  EOHELP
      macro :cryptocompare do |_obj, args|
        raise 'The correct usage is {{cryptocompare(options)}}' if args.empty?
        args, options = extract_macro_options(args, :fsym, :fsyms, :tsym, :tsyms, :period, :type)

        options[:fsym] = 'BTC' if options[:fsym].blank?
        options[:tsym] = 'EUR' if options[:tsym].blank?

        if options[:type].blank?
          widget_type = 'chart'
        else
          widget_type = options[:type]
          options.delete(:type)
        end

        base_url = 'https://widgets.cryptocompare.com/'

        case widget_type
        when 'chart'
          url = base_url + 'serve/v2/coin/chart'
        when 'news'
          options[:feedType] = 'CoinTelegraph' if options[:feedType].blank?
          url = base_url + 'serve/v1/coin/feed'
        when 'list'
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR,USD')
          options.delete(:tsym)
          url = base_url + 'serve/v1/coin/list'
        when 'titles'
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR,USD')
          options.delete(:tsym)
          url = base_url + 'serve/v1/coin/tiles'
        when 'tabbed'
          options[:fsyms] = RedmineTweaks.crypto_default(options, :fsyms, 'BTC,ETH,LTC')
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR,USD')
          options.delete(:fsym)
          options.delete(:tsym)
          url = base_url + 'serve/v1/coin/multi'
        when 'header', 'header_v1'
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR,USD')
          options.delete(:tsym)
          url = base_url + 'serve/v1/coin/header'
        when 'header_v2'
          options[:fsyms] = RedmineTweaks.crypto_default(options, :fsyms, 'BTC,ETH,LTC')
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR,USD')
          options.delete(:fsym)
          options.delete(:tsym)
          url = base_url + 'serve/v2/coin/header'
        when 'header_v3'
          options[:fsyms] = RedmineTweaks.crypto_default(options, :fsyms, 'BTC,ETH,LTC')
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR')
          options.delete(:fsym)
          options.delete(:tsym)
          url = base_url + 'serve/v3/coin/header'
        when 'summary'
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR,USD')
          options.delete(:tsym)
          url = base_url + 'serve/v1/coin/summary'
        when 'historical'
          url = base_url + 'serve/v1/coin/histo_week'
        when 'converter'
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR,USD')
          options.delete(:tsym)
          url = base_url + 'serve/v1/coin/converter'
        when 'advanced'
          options[:tsyms] = RedmineTweaks.crypto_default(options, :tsyms, 'EUR,USD')
          options.delete(:tsym)
          url = base_url + 'serve/v3/coin/chart'
        else
          raise 'type is not supported'
        end

        render partial: 'wiki/cryptocompare', locals: { url: url + '?' + options.map { |k, v| "#{k}=#{v}" }.join('&') }
      end
    end
  end

  def self.crypto_default(options, name, defaults)
    if options[name].blank?
      defaults
    else
      options[name].tr(';', ',')
    end
  end
end
