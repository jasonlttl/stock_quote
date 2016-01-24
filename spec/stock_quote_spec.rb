require 'stock_quote'
require 'spec_helper'

describe StockQuote::Stock do
  describe 'quote' do
    context 'success' do
      describe 'single symbol' do

        @fields = StockQuote::Stock::FIELDS

        #use_vcr_cassette 'aapl'

        @fields.each do |field|
          it ".#{to_underscore(field)}" do
            VCR.use_cassette('stock/aapl') do
              @stock = StockQuote::Stock.quote('aapl')
            end
            @stock.should respond_to(to_underscore(field).to_sym)
          end

          it ".#{field}" do
            VCR.use_cassette('stock/aapl') do
              @stock = StockQuote::Stock.quote('aapl')
            end
            @stock.should respond_to(field.to_sym)
          end
        end

        it 'should use underscore getter method for the underscore instance variable' do
          @stock = StockQuote::Stock.new({ 'AdjClose' => 123 })
          expect(@stock.adj_close).to eq(123)
          expect(@stock.AdjClose).to eq(123)
        end

        it 'should result in a successful query with ' do
          VCR.use_cassette('stock/aapl') do
            @stock = StockQuote::Stock.quote('aapl')
          end
          @stock.response_code.should be_eql(200)
          @stock.should respond_to(:no_data_message)
          @stock.no_data_message.should be_nil
        end

        describe "should select specific fields" do
          it "as string" do
            VCR.use_cassette('stock/aapl-sab') do
              @stock = StockQuote::Stock.quote('aapl', nil, nil, 'Symbol,Ask,Bid')
            end
            @stock.response_code.should be_eql(200)
            @stock.should respond_to(:no_data_message)
            @stock.no_data_message.should be_nil
          end

          it "as array" do
            VCR.use_cassette('stock/aapl-sab') do
              @stock = StockQuote::Stock.quote('aapl', nil, nil, ['Symbol','Ask','Bid'])
            end
            @stock.response_code.should be_eql(200)
            @stock.should respond_to(:no_data_message)
            @stock.no_data_message.should be_nil
          end
        end
      end
    end

    describe 'comma seperated symbols' do

      it 'should result in a successful query' do
        VCR.use_cassette('stock/aapl-tsla') do
          @stocks = StockQuote::Stock.quote('aapl,tsla')
        end
        @stocks.each do |stock|
          stock.response_code.should be_eql(200)
          stock.should respond_to(:no_data_message)
          stock.no_data_message.should be_nil
        end
      end
    end

    context 'failure' do

      @fields = StockQuote::Stock::FIELDS

      # Yahoo API returns a stock with null values all around
      #it 'should fail... gracefully if no data is found for that ticker' do
      #  VCR.use_cassette('stock/asdf') do
      #    @stock = StockQuote::Stock.quote('asdf')
      #  end
      #  @stock.response_code.should be_eql(404)
      #  @stock.should respond_to(:no_data_message)
      #  @stock.no_data_message.should_not be_nil
      #end

      it 'should fail... gracefully if the request errors out' do
        VCR.use_cassette('stock/malformed') do
          stock = StockQuote::Stock.quote('\/')
          expect(stock.response_code).to eql(404)
        end

        # Todo: fix this for yahoo
        # expect(stock).to be_instance_of(StockQuote::NoDataForStockError)
      end
    end
  end

  describe 'history' do
    context 'success' do

      it 'should result in a successful query' do
        VCR.use_cassette('history/aapl20') do
          @stock = StockQuote::Stock.history('aapl', Date.today - 20)
        end
        @stock.count.should >= 1
      end

      it 'succesfuly queries history by default (no start date given' do
        VCR.use_cassette('history/aapl-nostart') do
          @stock = StockQuote::Stock.history('aapl')
        end
        expect(@stock.count).to be >= 1
      end

      it 'succesfuly queries history by default (no start date given' do
        VCR.use_cassette('history/aapl-range') do
          @stock = StockQuote::Stock.history(
            'aapl',
            Date.parse('20130103'),
            Date.parse('20130103')
          )
        end
        expect(@stock.count).to be == 1
      end
    end

    context 'failure' do

      # Yahoo sends stock with null data instead of 404
      # it 'should not result in a successful query' do
      #   VCR.use_cassette('history/asdf') do
      #     stock = StockQuote::Stock.history('asdf')
      #   end
      #   expect(stock.response_code).to eq(404)
      #   expect(stock).to respond_to(:no_data_message)
      #   expect(stock.no_data_message).not_to be_nil
      # end

      it 'should raise ArgumentError if start date is after end date' do
        expect do
          VCR.use_cassette('history/aapl-badrange') do
            s = StockQuote::Stock.history('aapl', Date.today + 2, Date.today)
          end
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe 'json' do
    context 'success' do
      describe 'single symbol' do

        it "it should return json" do
          VCR.use_cassette('json/aapl') do
            @stock = StockQuote::Stock.json_quote('aapl')
          end
          @stock.is_a?(Hash).should be_truthy
          @stock.should include('quote')
        end

        describe "should select specific fields" do
          it "as string" do
            VCR.use_cassette('json/aapl-sab') do
              @stock = StockQuote::Stock.json_quote('aapl', nil, nil, 'Symbol,Ask,Bid')
            end
            @stock.is_a?(Hash).should be_truthy
            @stock.should include('quote')
          end

          it "as array" do
            VCR.use_cassette('json/aapl-sab') do
              @stock = StockQuote::Stock.json_quote('aapl', nil, nil, ['Symbol','Ask','Bid'])
            end
            @stock.is_a?(Hash).should be_truthy
            @stock.should include('quote')
          end
        end
      end

      describe 'comma seperated symbols' do

        it 'should result in a successful query' do
          VCR.use_cassette('json/aapl-tsla') do
            @stocks = StockQuote::Stock.json_quote('aapl,tsla')
          end
          @stocks.is_a?(Hash).should be_truthy
          @stocks.should include('quote')
        end
      end

      describe 'history' do

        it 'should result in a successful query' do
          VCR.use_cassette('json-hist/aapl20') do
            @stock = StockQuote::Stock.json_history('aapl', Date.today - 20)
          end
          @stock.is_a?(Hash).should be_truthy
          @stock.should include('quote')
        end
      end
    end
  end

  # Not sure what this is supposed to do.
  # describe 'simple_return' do
  #   context 'success' do
  #
  #     it 'should result in a successful query' do
  #       VCR.use_cassette('simple/aapl') do
  #         simple_return = StockQuote::Stock.simple_return(
  #           'aapl',
  #           Date.parse('2012-01-03'),
  #           Date.parse('2012-01-20')
  #         )
  #       end
  #       expect(simple_return).to eq(2.205578386790845)
  #     end
  #
  #     it 'should return 0 if only one price is found' do
  #       VCR.use_cassette('simple/tsta') do
  #         simple_return = StockQuote::Stock.simple_return(
  #           'TSTA',
  #           Date.parse('20130201'),
  #           Date.parse('20130501')
  #         )
  #       end
  #       expect(simple_return).to eq(0)
  #     end
  #   end
  #
  #   context 'failure' do
  #
  #     it 'should not result in a successful query' do
  #       expect do
  #
  #         VCR.use_cassette('simple/asdf') do
  #           stock = StockQuote::Stock.simple_return(
  #             'asdf',
  #             Date.parse('2012-01-03'),
  #             Date.parse('2012-01-20')
  #           )
  #         end
  #       end.to raise_exception
  #     end
  #
  #     it 'should raise ArgumentError if start date is after end date' do
  #       expect do
  #
  #         VCR.use_cassette('simple/aapl-badrange') do
  #           s = StockQuote::Stock.simple_return('aapl', Date.today + 2, Date.today)
  #         end
  #       end.to raise_error(ArgumentError)
  #     end
  #   end
  # end
end
