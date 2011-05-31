require 'uri'
require 'json'
# FIXME: when ActiveSupport inclusion is working, this begin ... end sequence should be uncommented.
#begin
#  require 'active_support'
#rescue LoadError
#  require 'activesupport' # for Rails < 3.0
#end
# For some painfully, horribly, unknown reason, that is driving me to insanity,
# ActiveSupport isn't properly loading for me when running the test specs.
# So, I've commented out the require and pasted the code from ActiveSupport into the functions.

module PortableContacts
  
  # This is the main PortableContacts Client.
  #
  # == query options
  #
  # The library supports the various filter and sorting parameters. The format of this may change for this library, so limit use to :
  # :count and :start_index for now.
  #
  class Client
    attr :base_url, :access_token
    
    # First parameter is the portable contacts base_url. Find this on your PortableContact providers documentation or through XRDS.
    #
    # * Google's is http://www-opensocial.googleusercontent.com/api/people
    # * Yahoo's is http://appstore.apps.yahooapis.com/social/rest/people
    #
    # The second parameter is an OAuth::AccessToken instantiated for the provider.
    #
    def initialize(base_url,access_token)
      @base_url=base_url
      @access_token=access_token
    end
    
    # Returns the AccessToken users contact details. Note this requests all fields from provider
    # Returns an PortableContacts::Person object
    def me(options={})
      single(get("/@me/@self",options.reverse_merge(:fields=>:all)))
    end

    # Returns the contacts of the user. It defaults to all fields and 100 entries
    #
    #   @contacts = @client.all # return 100 contacts
    #   @contacts = @client.all :count=>10 # return 10 contacts
    #   @contacts = @client.all :count=>10, :start_index=>10 # returns the second page of 10 contacts
    #   puts @contacts.total_entries # returns the total amount of contacts on the server
    #
    # Returns a PortableContacts::Collection which is a subclass of Array
    def all(options={})
      collection(get("/@me/@all",options.reverse_merge(:fields=>:all,:count=>100)))
    end
    
    # Returns the full contact infor for a particular userid. TODO This is not tested well
    # Returns an PortableContacts::Person object
    def find(id, options={})
      single(get("/@me/@all/#{id}",options.reverse_merge(:fields=>:all)))
    end
    
    private

    def get(path,options={})
      parse(@access_token.get( url_for(path)+options_for(options), {'Accept' => 'application/json'}))
    end
    
    def url_for(path)
      "#{@base_url}#{path}"
    end
    
    def options_for(options={})
      return "" if options.nil? || options.empty?
      # FIXME: when ActiveSupport inclusion is working, the commented out line should replace the ones below it:
      #options.symbolize_keys! if options.respond_to? :symbolize_keys!
      options.keys.each do |key|
        options[(key.to_sym rescue key) || key] = options.delete(key)
      end
      "?#{(fields_options(options[:fields])+filter_options(options[:filter])+sort_options(options[:sort])+pagination_options(options)).sort.join("&")}"
    end
    
    def single(data)
      if data.is_a?(Hash) && data['entry']
        PortableContacts::Person.new(data['entry'])
      else
        data
      end
    end
    
    def collection(data)
      if data.is_a?(Hash)
        PortableContacts::Collection.new data
      else
        data
      end
    end
    
    def parse(response)
      return false unless response
      if ["200","201"].include? response.code
        unless response.body.blank?
          JSON.parse(response.body)
        else
          true
        end
      else
        false
      end  
    end
    
    def fields_options(options=nil)
      return [] if options.nil?
      if options.is_a? Symbol
        return ["fields=#{(options==:all ? "@all": URI.escape(options.to_s))}"]
      elsif options.respond_to?(:collect)
        ["fields=#{options.collect{|f|f.to_s}.join(',')}"]
      else
        []
      end
    end
    
    def sort_options(options=nil)
      return [] if options.nil?
      if options.is_a? Symbol
        return ["sortBy=#{URI.escape(options.to_s)}"]
      end
      if options.is_a?(Hash) and options[:by]||options['by']
        return to_query_list(options,"sort")
      end
      return []
    end

    def pagination_options(options=nil)
      return [] if options.nil? || options.empty?
      params=[]
      if options[:count]
        params<<"count=#{options[:count]}"
      end
      if options[:start_index]
        params<<"startIndex=#{options[:start_index]}"
      end
      params
    end
    
    def filter_options(options={})
      return [] if options.nil? || options.empty?
      options[:op] ||= "equals"
      to_query_list(options,"filter")
    end
    
    def to_query_list(params,pre_fix='')
      params.collect{ |k,v| "#{pre_fix}#{k.to_s.capitalize}=#{URI.escape(v.to_s)}"}
    end
  end
  
  class Person
    
    # Encapsulates a person. Each of the portable contact and opensocial contact fields has a rubyfied (underscored) accessor method.
    #
    # @person = @person.display_name
    #

    def initialize(data={})
      @data=data
    end
    
    SINGULAR_FIELDS = [
      # Portable contacts singular fields
      :id, :display_name, :name, :nickname, :published, :updated, :birthday, :anniversary,
      :gender, :note, :preferred_username, :utc_offset, :connected, 
      
      # OpenSocial singular fields
      :about_me, :body_type, :current_location, :drinker, :ethnicity, :fashion, :happiest_when, 
      :humor, :living_arrangement, :looking_for, :profile_song, :profile_video, :relationship_status, 
      :religion, :romance, :scared_of, :sexual_orientation, :smoker, :status
    ]
    PLURAL_FIELDS = [ 
      # Portable contacts plural fields
      :emails, :urls, :phone_numbers, :ims, :photos, :tags, :relationships, :addresses,
      :organizations, :accounts,
      
      # OpenSocial plural fields
      :activities, :books, :cars, :children, :food, :heroes, :interests, :job_interests, 
      :languages, :languages_spoken, :movies, :music, :pets, :political_views, :quotes, 
      :sports, :turn_offs, :turn_ons, :tv_shows
    ]
    
    ENTRY_FIELDS = SINGULAR_FIELDS + PLURAL_FIELDS
    
    
    def [](key)
      # FIXME: when ActiveSupport inclusion is working, the commented out line should replace the one below it:
      #@data[key.to_s.camelize(:lower)]
      @data[Inflector.camelize(key.to_s, false)]
    end
    
    # primary email address
    def email
      @email||= begin
        (emails.detect {|e| e['primary']=='true '} || emails.first)["value"] unless emails.empty?
      end
    end
    
    def id
      self["id"]
    end
    
    protected
    
    def method_missing(method,*args)
      if respond_to?(method)
        return self[method]
      end 
      super
    end
    
    def respond_to?(method)
      # FIXME: when ActiveSupport inclusion is working, the commented out line should replace the one below it:
      #ENTRY_FIELDS.include?(method) || @data.has_key?(method.to_s.camelize(:lower)) || super
      ENTRY_FIELDS.include?(method) || @data.has_key?(Inflector.camelize(method.to_s, false)) || super
    end
  end
  
  class Collection < Array
    attr_reader :total_entries, :per_page, :start_index
    
    def initialize(data)
      super data["entry"].collect{|e| PortableContacts::Person.new(e) }
      @total_entries=data["totalResults"].to_i
      @per_page=data["itemsPerPage"].to_i
      @start_index=data["startIndex"].to_i
    end

  end
  
  # FIXME: when ActiveSupport inclusion is working, delete this mini Inflector class
  class Inflector
    # straight copy from ActiveSupport::Inflector
    def self.camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        lower_case_and_underscored_word.to_s[0].chr.downcase + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end
  end
end