module Api
  module V1
    class MovieTheatersController < BaseController
      skip_before_action :set_resource

      def index
        @movie_theaters = parse_movie_theaters()
      end

      def show
        @movie_theater = parse_movie_theater(params[:id])
      end

      private

        def movie_theater_params
          params.require(:movie_theater)
        end

        # For index action
        def parse_cities
          html = Nokogiri::HTML(open('http://www.cinepolis.com.br/'))

          cities = []

          html.css('select[name=CIDADE] option').each do |option|
            if option.attr('value') != '0'
              city = {
                id: option.attr('value'),
                name: option.text
              }

              cities << city
            end
          end

          return cities
        end

        # For index action
        def parse_movie_theaters
          url = 'http://www.cinepolis.com.br/includes/getCinema.php'

          movie_theaters = []

          parse_cities().each do |city|
            response = HTTParty.post(url, {
              body: {
                cidade: city[:id]
              }
            })

            html = Nokogiri::HTML(response)

            html.css('option').each do |option|
              if option.attr('value') != '0'
                movie_theater = {
                  id: option.attr('value'),
                  name: option.text,
                  city: {
                    id: city[:id],
                    name: city[:name]
                  },
                  url: "#{request.protocol}#{request.host}:#{request.port}#{api_v1_movie_theater_path(option.attr('value'), format: :json)}"
                }

                movie_theaters << movie_theater
              end
            end
          end

          return movie_theaters
        end

        # For show action
        def parse_movie_theater(movie_theater_id)
          html = Nokogiri::HTML(open("http://www.cinepolis.com.br/programacao/cinema.php?cc=#{movie_theater_id}"))

          # GET MOVIE DATA:
          # http://www.cinepolis.com.br/programacao/busca.php?cidade=16&cc=16&cf=8344

          movie_theater = {
            name: html.css('.titulo .amarelo')[0].text,
            location: html.css('.titulo .cinza .esquerda')[0].text,
            movies: []
          }

          movies = []
          
          url = 'http://www.cinepolis.com.br/includes/getFilme.php'
          response = HTTParty.post(url, {
            body: {
              type: '0',
              cidade: movie_theater_id
            }
          })

          html = Nokogiri::HTML(response)

          # loop each movie
          html.css('option').each do |option|

            if option.attr('value') != '0'

              html = Nokogiri::HTML(open("http://www.cinepolis.com.br/programacao/busca.php?cidade=#{movie_theater_id}&cc=16&cf=#{option["value"]}"))
              trailer = Nokogiri::HTML(open(html.css('.linha2 .coluna1 a')[1].attr('href')))

              movie = {
                id: option.attr('value'),
                name: option.text,
                synopsis: html.css('.linha2 .coluna2 p')[0].text,
                cast: html.css('.linha2 .coluna2 p')[1].text,
                director: html.css('.linha2 .coluna2 p')[2].text,
                classification: html.css('.titulo img')[0].attr('alt').gsub(/\D/, ''),
                image: html.css('.linha2 .coluna1 img')[0].attr('src').gsub('medio', 'grande'),
                trailer: trailer.css('iframe')[0].attr('src'),
                remaining_days: []
              }

              remaining_days = []

              html.css('.tabs3 .tabNavigation li').each do |li|
                
                day = {
                  date: 'abc'
                }
                
                remaining_days << day
              end

              movies << movie
            end
          end

          movie_theater[:movies] = movies

          return movie_theater
        end 
    end
  end
end