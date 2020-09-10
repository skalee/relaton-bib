module RelatonBib
  # Document identifier.
  class DocumentIdentifier
    # @return [String]
    attr_reader :id

    # @return [String, NilClass]
    attr_reader :type, :scope

    # @param id [String]
    # @param type [String, NilClass]
    # @param scoope [String, NilClass]
    def initialize(id:, type: nil, scope: nil)
      @id    = id
      @type  = type
      @scope = scope
    end

    # in docid manipulations, assume ISO as the default: id-part:year
    def remove_part
      case @type
      when "Chinese Standard" then @id.sub!(/\.\d+/, "")
      when "ISO", "IEC" then @id.sub!(/-[^:]+/, "")
      when "URN" then remove_urn_part
      end
    end

    def remove_date
      case @type
      when "Chinese Standard" then @id.sub!(/-[12]\d\d\d/, "")
      when "ISO", "IEC" then @id.sub!(/:[12]\d\d\d/, "")
      when "URN"
        @id.sub!(/^(urn:iec:std:[^:]+:[^:]+:)[^:]*/, '\1')
      end
    end

    def all_parts
      if type == "URN"
        @id.sub!(%r{^(urn:iec:std(?::[^:]*){4}).*}, '\1:ser')
      else
        @id += " (all parts)"
      end
    end

    #
    # Add docidentifier xml element
    #
    # @param [Nokogiri::XML::Builder] builder
    #
    def to_xml(builder)
      element = builder.docidentifier id
      element[:type] = type if type
      element[:scope] = scope if scope
    end

    # @return [Hash]
    def to_hash
      hash = { "id" => id }
      hash["type"] = type if type
      hash["scope"] = scope if scope
      hash
    end

    # @param prefix [String]
    # @param count [Integer] number of docids
    # @return [String]
    def to_asciibib(prefix = "", count = 1)
      pref = prefix.empty? ? prefix : prefix + "."
      out = count > 1 ? "#{pref}docid::\n" : ""
      out += "#{pref}docid.type:: #{type}\n" if type
      out += "#{pref}docid.scope:: #{scope}\n" if scope
      out += "#{pref}docid.id:: #{id}\n"
      out
    end

    private

    def remove_urn_part # rubocop:disable Metrics/MethodLength
      @id.sub!(%r{^
        (urn:iso:std:[^:]+ # ISO prefix and originator
          (?::(?:data|guide|isp|iwa|pas|r|tr|ts|tta)) # type
          ?:\d+) # docnumber
        (?::-[^:]+)? # partnumber
        (?::(draft|cancelled|stage-[^:]+))? # status
        (?::ed-\d+)?(?::v[^:]+)? # edition and version
        (?::\w{2}(?:,\w{2})*)? # langauge
      }x, '\1') # remove partnumber, status, version, and language
      @id.sub!(%r{^
        (urn:iec:std:[^:]+ # IEC prefix and originator
          ?:\d+) # docnumber
        (?:-[^:]+)? # partnumber
      }x, '\1') # remove partnumber
    end
  end
end
