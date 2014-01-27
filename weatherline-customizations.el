;;; weatherline-customizations.el --- weatherline configurability

;; THIS IS NOT DONE YET. DON'T USE IT. SRSLY.

(require 'url)
(require 'json)

(defgroup weatherline nil
  "Customization options for the Weatherline minor mode."
  :prefix "weatherline-")

(defcustom weatherline-location ""
  "The location whose weather you wish reflected in the mode
  line. Generally of form 'City,CC' where 'CC' is a country code;
  see http://openweathermap.org/ for more."
  :group 'weatherline
  :tag "Location"
  :type '(string)
  :set #'(lambda (sym val)
           (set-default sym val)
           (and (fboundp 'weatherline-fetch-update)
                (weatherline-fetch-update)))
  :link '(url-link "http://www.openweathermap.org"))

(defcustom weatherline-location-id nil
  "The numeric ID for the location corresponding to the value of
`weatherline-location'; if defined, this is used when opening a
browser on OpenWeatherMap to bypass the disambiguation page
ordinarily presented for a location which has multiple city
IDs. Otherwise, the value of `weatherline-location' is used when
opening the browser."
  :group 'weatherline
  :tag "Location ID"
  :type '(integer))

(defcustom weatherline-request-set-location-id t
  "Whether or not to ask, when examining an API response and no
location ID has been set, to set the location ID to that provided
in the API response."
  :group 'weatherline
  :tag "Ask to set location ID from API response?"
  :type '(choice (const :tag "No" nil)
                 (const :tag "Yes" t)))

(defcustom weatherline-units "imperial"
  "The system of measurement in which to display weather
  information.

Changing this variable in Customize sets
`weatherline-temperature-indicator' accordingly ('°F' for
Imperial, '°C' for metric). If you change this variable outside
Customize, you will no longer get
`weatherline-temperature-indicator' for free."
  :group 'weatherline
  :tag "Units"
  :type '(choice (const :tag "Metric" "metric")
                 (const :tag "Imperial" "imperial"))
  :set #'(lambda (sym val)
           (if (string= val "imperial")
               (progn
                 (setq weatherline-temperature-indicator "°F"))
             (progn
               (setq weatherline-temperature-indicator "°C")))
           (set-default sym val)))

(defcustom weatherline-update-interval "30 min"
  "The approximate interval between Weatherline updates. Specify
  this in the relative time format described for
  `timer-duration', e.g. \"30 min\", \"2 hours\", &c. The value
  given will be passed through `timer-duration' before being
  set, and will be rejected if invalid."
  :group 'weatherline
  :tag "Update interval"
  :type '(string
          :validate (lambda (widget)
                      (if (timer-duration (widget-value widget)) nil
                        (progn
                          (widget-put widget
                                      :error "Invalid relative time specification.")
                          widget))))
  :set #'(lambda (sym val)
           (set-default sym val)
           (if (fboundp 'weatherline-update-timer)
               (weatherline-update-timer)))
  :link '(function-link timer-duration))

;;; WHEEEEEEEEEE :D

(defcustom weatherline-api-code-map
  '(;; 1xx: (not currently defined)
    ;; 2xx: thunderstorms
    (200 . "thunderstorm with light rain") (201 . "thunderstorm with rain")
    (202 . "thunderstorm with heavy rain") (210 . "light thunderstorm")
    (211 . "thunderstorm") (212 . "heavy thunderstorm")
    (221 . "ragged thunderstorm") (230 . "thunderstorm with light drizzle")
    (231 . "thunderstorm with drizzle") (232 . "thunderstorm with heavy drizzle")
    ;; 3xx: drizzle
    (300 . "light drizzle") (301 . "drizzle")
    (302 . "heavy drizzle") (310 . "light drizzle rain")
    (311 . "drizzle rain") (312 . "heavy drizzle rain")
    (313 . "shower rain and drizzle") (314 . "heavy shower rain and drizzle")
    (321 . "shower drizzle")
    ;; 4xx: (not currently defined)
    ;; 5xx: rain
    (500 . "light rain") (501 . "moderate rain")
    (502 . "heavy rain") (503 . "very heavy rain")
    (504 . "extreme rain") (511 . "freezing rain")
    (520 . "light shower rain") (521 . "shower rain")
    (522 . "heavy shower rain") (531 . "ragged shower rain")
    ;; 6xx: snow
    (600 . "light snow") (601 . "snow")
    (602 . "heavy snow") (611 . "sleet")
    (612 . "shower sleet") (615 . "light rain and snow")
    (616 . "rain and snow") (620 . "light shower snow")
    (621 . "shower snow") (622 . "heavy shower snow")
    ;; 7xx: atmospheric conditions
    (701 . "mist") (711 . "smoke")
    (721 . "haze") (731 . "dust devils")
    (741 . "fog") (751 . "sand")
    (761 . "dust") (762 . "volcanic ash")
    (771 . "squalls") (781 . "tornado")
    ;; 8xx: clouds
    (800 . "clear") (801 . "few clouds")
    (802 . "scattered clouds") (803 . "broken clouds")
    (804 . "overcast")
    ;; 90x: extreme weather
    (900 . "tornado") (901 . "tropical storm")
    (902 . "hurricane") (903 . "extreme cold")
    (904 . "extreme heat") (905 . "extreme wind")
    (906 . "hail")
    ;; 95x, 96x: wind speeds
    (950 . "setting") (951 . "calm")
    (952 . "light breeze") (953 . "gentle breeze")
    (954 . "moderate breeze") (955 . "fresh breeze")
    (956 . "strong breeze") (957 . "near gale")
    (958 . "gale") (959 . "severe gale")
    (960 . "storm") (961 . "violent storm")
    (962 . "hurricane"))
  "A mapping between OpenWeatherMap API weather condition codes
and the names of the weather conditions they denote."
  :group 'weatherline
  :tag "Condition ID names"
  :type '(alist :key-type   (integer :tag "Code")
                :value-type (string  :tag "Name"))
  :link '(url-link
          "http://bugs.openweathermap.org/projects/api/wiki/Weather_Condition_Codes"))

(defcustom weatherline-condition-indicators
  '(;; 1xx: (not currently defined)
    
    ;; 2xx: thunderstorms
    ;; 200
    ("thunderstorm with light rain". (:day ? :night ? :string "Tstm"))
    ;; 201
    ("thunderstorm with rain". (:day ? :night ? :string "Tstm"))
    ;; 202
    ("thunderstorm with heavy rain". (:day ? :night ? :string "Tstm"))
    ;; 210
    ("light thunderstorm". (:day ? :night ? :string "Tstm"))
    ;; 211
    ("thunderstorm". (:day ? :night ? :string "Tstm"))
    ;; 212
    ("heavy thunderstorm". (:day ? :night ? :string "Tstm"))
    ;; 221
    ("ragged thunderstorm". (:day ? :night ? :string "Tstm"))
    ;; 230
    ("thunderstorm with light drizzle". (:day ? :night ? :string "Tstm"))
    ;; 231
    ("thunderstorm with drizzle". (:day ? :night ? :string "Tstm"))
    ;; 232
    ("thunderstorm with heavy drizzle". (:day ? :night ? :string "Tstm"))
    
    ;; 3xx: drizzle
    ;; 300
    ("light drizzle". (:day ? :night ? :string "Drzl"))
    ;; 301
    ("drizzle". (:day ? :night ? :string "Drzl"))
    ;; 302
    ("heavy drizzle". (:day ? :night ? :string "Drzl"))
    ;; 310
    ("light drizzle rain". (:day ? :night ? :string "Drzl"))
    ;; 311
    ("drizzle rain". (:day ? :night ? :string "Drzl"))
    ;; 312
    ("heavy drizzle rain". (:day ? :night ? :string "Drzl"))
    ;; 313
    ("shower rain and drizzle". (:day ? :night ? :string "Drzl"))
    ;; 314
    ("heavy shower rain and drizzle". (:day ? :night ? :string "Drzl"))
    ;; 321
    ("shower drizzle". (:day ? :night ? :string "Drzl"))
    
    ;; 4xx: (not currently defined)
    
    ;; 5xx: rain
    ;; 500
    ("light rain". (:day ? :night ? :string "Rain"))
    ;; 501
    ("moderate rain". (:day ? :night ? :string "Rain"))
    ;; 502
    ("heavy rain". (:day ? :night ? :string "Rain"))
    ;; 503
    ("very heavy rain". (:day ? :night ? :string "Rain"))
    ;; 504
    ("extreme rain". (:day ? :night ? :string "Rain"))
    ;; 511
    ("freezing rain". (:day ? :night ? :string "Rain"))
    ;; 520
    ("light shower rain". (:day ? :night ? :string "Rain"))
    ;; 521
    ("shower rain". (:day ? :night ? :string "Rain"))
    ;; 522
    ("heavy shower rain". (:day ? :night ? :string "Rain"))
    ;; 531
    ("ragged shower rain". (:day ? :night ? :string "Rain"))
    
    ;; 6xx: snow
    ;; 600
    ("light snow". (:day ? :night ? :string "Snow"))
    ;; 601
    ("snow". (:day ? :night ? :string "Snow"))
    ;; 602
    ("heavy snow". (:day ? :night ? :string "Snow"))
    ;; 611
    ("sleet". (:day ? :night ? :string "Snow"))
    ;; 612
    ("shower sleet". (:day ? :night ? :string "Slt"))
    ;; 615
    ("light rain and snow". (:day ? :night ? :string "Snow"))
    ;; 616
    ("rain and snow". (:day ? :night ? :string "Snow"))
    ;; 620
    ("light shower snow". (:day ? :night ? :string "Snow"))
    ;; 621
    ("shower snow". (:day ? :night ? :string "Snow"))
    ;; 622
    ("heavy shower snow". (:day ? :night ? :string "Snow"))
    
    ;; 7xx: atmospheric conditions
    ;; 701
    ("mist". (:day ? :night ? :string "Mist"))
    ;; 711
    ("smoke". (:day ? :night ? :string "Smke"))
    ;; 721
    ("haze". (:day ? :night ? :string "Haze"))
    ;; 731
    ("dust devils". (:day ? :night ? :string "DDvl"))
    ;; 741
    ("fog". (:day ? :night ? :string "Fog"))
    ;; 751
    ("sand". (:day ? :night ? :string "Sand"))
    ;; 761
    ("dust". (:day ? :night ? :string "Dust"))
    ;; 762
    ("volcanic ash". (:day ? :night ? :string "Ash"))
    ;; 771
    ("squalls". (:day ? :night ? :string "Sqls"))
    ;; 781
    ("tornado". (:day ? :night ? :string "Tndo"))
    
    ;; 8xx: clouds
    ;; 800
    ("clear". (:day ? :night ? :string "Clr"))
    ;; 801
    ("few clouds". (:day ? :night ? :string "Clds"))
    ;; 802
    ("scattered clouds". (:day ? :night ? :string "Clds"))
    ;; 803
    ("broken clouds". (:day ? :night ? :string "Clds"))
    ;; 804
    ("overcast". (:day ? :night ? :string "Ovct"))
    
    ;; 90x: extreme weather
    ;; 900
    ("tornado". (:day ? :night ? :string "Tndo"))
    ;; 901
    ("tropical storm". (:day ? :night ? :string "TStm"))
    ;; 902
    ("hurricane". (:day ? :night ? :string "Hcne"))
    ;; 903
    ("extreme cold". (:day ?! :night ?! :string "Cld!"))
    ;; 904
    ("extreme heat". (:day ?! :night ?! :string "Hot!"))
    ;; 905
    ("extreme wind". (:day ?! :night ?! :string "Wnd!"))
    ;; 906
    ("hail". (:day ? :night ? :string "Hail"))
    
    ;; 95x, 96x: wind speeds
    ;; 950
    ("setting". (:day ?  :night ?  :string "Stng"))
    ;; 951
    ("calm". (:day ?  :night ?  :string "Calm"))
    ;; 952
    ("light breeze". (:day ? :night ? :string "Wnd1"))
    ;; 953
    ("gentle breeze". (:day ? :night ? :string "Wnd2"))
    ;; 954
    ("moderate breeze". (:day ? :night ? :string "Wnd3"))
    ;; 955
    ("fresh breeze". (:day ? :night ? :string "Wnd4"))
    ;; 956
    ("strong breeze". (:day ? :night ? :string "Wnd5"))
    ;; 957
    ("near gale". (:day ? :night ? :string "Wnd6"))
    ;; 958
    ("gale". (:day ? :night ? :string "Wnd7"))
    ;; 959
    ("severe gale". (:day ? :night ? :string "Wnd8"))
    ;; 960
    ("storm". (:day ? :night ? :string "Wnd9"))
    ;; 961
    ("violent storm". (:day ? :night ? :string "Wnd!"))
    ;; 962
    ("hurricane". (:day ? :night ? :string "Hcne")))

  "A mapping between OpenWeatherMap API weather condition names
and their representation in the mode line.

For lookup to succeed, the keys in this alist must match names
assigned as values in `weatherline-api-condition-id-names'.

Three representations exist for each condition: two Unicode
characters, one for daytime and one for nighttime, and a string
which will be displayed when the icon font isn't available."
  :group 'weatherline
  :tag "Condition indicators"
  :type '(alist :key-type   (string :tag "Name")
                :value-type (plist :tag "Indicators"
                                   :options ((:day character)
                                             (:night character)
                                             (:string string))))
  :link '(url-link
          "http://bugs.openweathermap.org/projects/api/wiki/Weather_Condition_Codes"))

(defcustom weatherline-indicator-type t
  "The form in which to display weather conditions in the mode
line."
  :group 'weatherline
  :tag "Indicator type"
  :type '(choice (const :tag "String" nil)
                 (const :tag "Symbol" t)))

(defface weatherline-mode-line-symbol-face
  `((t (:inherit 'weatherline-mode-line-string-face
        :family "Weather Icons")))
  "Face for icons (Unicode symbols) in the mode line weather
information display."
  :group 'weatherline
  :tag "Mode line face for symbols")

(defface weatherline-mode-line-string-face
  `((((class color) (background light))
     (:foreground "black"))
    (((class color) (background dark))
     (:foreground "white"))
    (t (:foreground "black")))
  "Face for text in the mode line weather information display."
  :group 'weatherline
  :tag "Mode line face for strings")


(provide 'weatherline-customizations)

;; weatherline-mode.el ends here.
