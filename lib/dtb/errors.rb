# frozen_string_literal: true

module DTB
  # Mixin for other errors raised from this library, so that you can always
  # rescue +DTB::Error+.
  module Error; end

  # Raised when initializing an object that supports options with an option that
  # hasn't been defined.
  #
  # @see HasOptions
  # @see OptionsMap
  class UnknownOptionsError < ArgumentError
    include DTB::Error

    # @return [OptionsMap] The invalid options hash.
    attr_reader :options

    # @return [Set] The options that are defined for this hash.
    attr_reader :valid_options

    # @return [Set] The options that are present in the Hash that aren't defined.
    attr_reader :unknown_options

    # @api private
    def initialize(options)
      unknown = options.keys.to_set - options.valid_keys
      super(format(MESSAGE, unknown.to_a, options.valid_keys.to_a))
      @options = options
      @valid_options = options.valid_keys
      @unknown_options = unknown
    end

    MESSAGE = "Unknown options: %p. Valid options are: %p"
    private_constant :MESSAGE
  end

  # Raised when initializing an object that supports options without passing all
  # the required options.
  #
  # @see HasOptions
  # @see OptionsMap
  class MissingOptionsError < ArgumentError
    include DTB::Error

    # @return [OptionsMap] The invalid options hash.
    attr_reader :options

    # @return [Set] The options that are required for this Hash.
    attr_reader :required_options

    # @return [Set] The required options that are missing from this Hash.
    attr_reader :missing_options

    # @api private
    def initialize(options)
      missing = options.required_keys - options.keys
      super(format(MESSAGE, missing.to_a, options))
      @options = options
      @required_options = options.required_keys
      @missing_options = missing
    end

    MESSAGE = "Missing required options: %p. Options given were: %p"
    private_constant :MESSAGE
  end

  # rubocop:disable Lint/InheritException

  # Extends +NotImplementedError+ to be catchable as a library error via
  # +rescue DTB::Error+. Normally you wouldn't rescue this in code, though,
  # but rather use it to get failing tests / exceptions while developing.
  class NotImplementedError < ::NotImplementedError
    include DTB::Error
  end
  # rubocop:enable Lint/InheritException
end
