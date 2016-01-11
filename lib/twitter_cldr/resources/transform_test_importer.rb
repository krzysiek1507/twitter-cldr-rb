# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'java'
require 'fileutils'

module TwitterCldr
  module Resources

    # This class should be used with JRuby in 1.9 mode
    class TransformTestImporter < IcuBasedImporter

      attr_reader :output_file, :icu4j_path

      # most of these were taken from wikipedia, lol
      TEXT_SAMPLES = {
        latin: ["From today's featured article"],  # @TODO test capital letters,
        serbian: ["На данашњи дан"],
        oriya: ["ଉଇକିପିଡ଼ିଆ ବ୍ୟବହାର କରିବେ କିପରି"],
        kannada: ["ಈ ತಿಂಗಳ ಪ್ರಮುಖ ದಿನಗಳು"],
        gurmukhi: ["ਅੱਜ ਇਤਿਹਾਸ ਵਿੱਚ"],
        gujarati: ["આ માસનો ઉમદા લેખ"],
        bengali: ["নির্বাচিত নিবন্ধ"],
        hangul: ["김창옥"],
        arabic: ["مقالة اليوم المختارة"],
        han: ["因此只有两场风暴因造成"],
        hiragana: ["くろねこさま"],
        greek: ["Αλφαβητικός Κατάλογος"],
        cyrillic: ["Влади́мир Влади́мирович Пу́тин"]
      }

      def initialize(output_file, icu4j_path)
        @output_file = output_file
        @icu4j_path = icu4j_path
      end

      def import
        require_icu4j(icu4j_path)

        File.open(output_file, 'w+') do |f|
          f.write(
            YAML.dump(
              generate_test_data(transformer.each_transform)
            )
          )
        end
      end

      def generate_test_data(transforms)
        transforms.each_with_object([]) do |transform_id_str, ret|
          forward_id = transform_id.parse(transform_id_str)

          [forward_id, forward_id.reverse].each do |id|
            if id_exists?(id) && have_text_samples_for?(id.source)
              samples = text_samples_for(id.source)
              transformed_samples = generate_transform_samples(id, samples)

              if transformed_samples
                ret << {
                  id: id.to_s,
                  samples: transformed_samples
                }
              end
            end
          end
        end
      end

      private

      def id_exists?(id)
        TwitterCldr::Transforms::Transformer.exists?(id)
      end

      def generate_transform_samples(id, samples)
        trans = com.ibm.icu.text.Transliterator.getInstance(id.to_s)
        samples.each_with_object({}) do |sample, ret|
          ret[sample] = trans.transliterate(sample)
        end
      rescue Java::JavaLang::IllegalArgumentException
        # illegal transform id
        # this happens specifically with Serbian-Latin, although
        # that appears to be a totally valid transform id
        nil
      end

      def have_text_samples_for?(script)
        TEXT_SAMPLES.include?(script.downcase.to_sym)
      end

      def text_samples_for(script)
        TEXT_SAMPLES.fetch(script.downcase.to_sym)
      end

      def transformer
        TwitterCldr::Transforms::Transformer
      end

      def transform_id
        TwitterCldr::Transforms::TransformId
      end

    end
  end
end