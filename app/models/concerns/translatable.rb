# Chinese is always shown; English and Indonesian are the translations the viewer switches between.
# `translates :name` adds `name_tr`, which reads `name_en` or `name_id` for the current locale.
module Translatable
  extend ActiveSupport::Concern

  class_methods do
    def translates(*attrs)
      attrs.each do |attr|
        define_method(:"#{attr}_tr") { public_send(:"#{attr}_#{Translatable.locale}") }
      end
    end

    # For JSON columns shaped { "en" => [...], "id" => [...] }
    def translates_list(*attrs)
      attrs.each do |attr|
        define_method(:"#{attr}_tr") { Array(public_send(attr)&.fetch(Translatable.locale, nil)) }
      end
    end
  end

  def self.locale = I18n.locale.to_s == "id" ? "id" : "en"
end
