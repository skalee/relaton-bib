# frozen_string_literal: true

require "relaton_bib/contributor"

module RelatonBib
  # Person's full name
  class FullName
    # @return [Array<RelatonBib::LocalizedString>]
    attr_accessor :forenames

    # @return [Array<RelatonBib::LocalizedString>]
    attr_accessor :initials

    # @return [RelatonBib::LocalizedString]
    attr_accessor :surname

    # @return [Array<RelatonBib::LocalizedString>]
    attr_accessor :additions

    # @return [Array<RelatonBib::LocalizedString>]
    attr_accessor :prefix

    # @return [RelatonBib::LocalizedString]
    attr_reader :completename

    # @param surname [RelatonBib::LocalizedString]
    # @param forenames [Array<RelatonBib::LocalizedString>]
    # @param initials [Array<RelatonBib::LocalizedString>]
    # @param prefix [Array<RelatonBib::LocalizedString>]
    # @param completename [RelatonBib::LocalizedString]
    def initialize(**args)
      unless args[:surname] || args[:completename]
        raise ArgumentError, "Should be given :surname or :completename"
      end

      @surname      = args[:surname]
      @forenames    = args[:forenames]
      @initials     = args[:initials]
      @additions    = args[:additions]
      @prefix       = args[:prefix]
      @completename = args[:completename]
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.name do
        if completename
          builder.completename { completename.to_xml builder }
        else
          builder.prefix { prefix.each { |p| p.to_xml builder } } if prefix
          builder.initial { initials.each { |i| i.to_xml builder } } if initials
          builder.addition { additions.each { |a| a.to_xml builder } } if additions
          builder.surname { surname.to_xml builder }
          builder.forename { forenames.each { |f| f.to_xml builder } } if forenames
        end
      end
    end
  end

  # Person identifier type.
  module PersonIdentifierType
    ISNI = "isni"
    URI  = "uri"

    # Checks type.
    # @param type [String]
    # @raise [ArgumentError] if type isn't "isni" or "uri"
    def self.check(type)
      unless [ISNI, URI].include? type
        raise ArgumentError, 'Invalid type. It should be "isni" or "uri".'
      end
    end
  end

  # Person identifier.
  class PersonIdentifier
    # @return [RelatonBib::PersonIdentifierType::ISNI, RelatonBib::PersonIdentifierType::URI]
    attr_accessor :type

    # @return [String]
    attr_accessor :value

    # @param type [RelatonBib::PersonIdentifierType::ISNI, RelatonBib::PersonIdentifierType::URI]
    # @param value [String]
    def initialize(type, value)
      PersonIdentifierType.check type

      @type  = type
      @value = value
    end

    # @param builser [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.identifier value, type: type
    end
  end

  # Person class.
  class Person < Contributor
    # @return [RelatonBib::FullName]
    attr_accessor :name

    # @return [Array<RelatonBib::Affilation>]
    attr_accessor :affiliation

    # @return [Array<RelatonBib::PersonIdentifier>]
    attr_accessor :identifiers

    # @param name [RelatonBib::FullName]
    # @param affiliation [Array<RelatonBib::Affiliation>]
    # @param contacts [Array<RelatonBib::Address, RelatonBib::Phone>]
    # @param identifiers [Array<RelatonBib::PersonIdentifier>]
    def initialize(name:, affiliation: [], contacts: [], identifiers: [])
      super(contacts: contacts)
      @name        = name
      @affiliation = affiliation
      @identifiers = identifiers
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.person do
        name.to_xml builder
        affiliation.each { |a| a.to_xml builder }
        identifiers.each { |id| id.to_xml builder }
        contacts.each { |contact| contact.to_xml builder }
      end
    end
  end
end
