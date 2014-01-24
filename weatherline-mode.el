;;; weatherline-mode.el --- Current weather in your Emacs mode line.

;; Copyright (C) 2013 Aaron Miller. All rights reversed.
;; Share and Enjoy!

;; Last revision: Monday, December 17, 2013, ca. 00:00.

;; Author: Aaron Miller <me@aaron-miller.me>

;; This file is not part of Emacs.

;; weatherline-mode.el is free software; you can redistribute it
;; and/or modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.

;; weatherline-mode.el is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied warranty
;; of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see `http://www.gnu.org/licenses'.

;;; Commentary:

;; A little while ago, a Bash script called 'ansiweather' [1] turned
;; up on Hacker News. It's a cute little tool which retrieves weather
;; data for a given location from the OpenWeatherMap.org API, and
;; renders it in a colorful format in your terminal.

;; In the Hacker News comments, someone said [2] this: "I need this as
;; an emacs extension. Would fit right next to my nyan cat progress
;; bar[3]."

;; "Why," I thought, "I can do that! It'll be an interesting
;; exercise." Indeed it was. I now know a great deal about the Emacs
;; customization interface, mode line display, and HTTP client
;; library; this pleases me. Perhaps the result of these explorations
;; will please you too.

;; To use weatherline-mode, drop this file into your Emacs load path,
;; then (require 'weatherline-mode). Before invoking the mode, you'll
;; probably want to set a location for which to receive weather data;
;; by default, none is set. Do this via M-x customize-group RET
;; weatherline RET and setting the "Location" variable
;; (`weatherline-location'); the required form for location values is
;; given in the variable documentation, along with a link to
;; OpenWeatherMap.org should you desire to investigate further.

;; Once that's done, along with any other customizations you'd like to
;; make, M-x weatherline-mode will enable the mode line display and
;; fetch the current weather data. (If you forget to set a location
;; before enabling the mode, never fear; it will notice and suggest a
;; course of action, and decline further to bother you on the subject
;; until you've given it enough information to start doing its job.)

;; OpenWeatherMap uses numeric location IDs in addition to textual
;; search strings; a given search string (e.g. "Baltimore,US") might
;; map to more than one numeric ID. On the OpenWeatherMap webpage,
;; this results in a disambiguation page; in an API request, it
;; appears that the likeliest location is automatically chosen, for
;; some value of 'likeliest' which might include IP geolocation but
;; probably just relies on relative size.

;; If you already know your location's numeric ID, you can supply it
;; as the value for `weatherline-location-id'. Otherwise, the first
;; successful API request will elicit a prompt asking whether you'd
;; like to use the included location ID in links to the OpenWeatherMap
;; webpage for your current location. (This avoids the need to go
;; through a disambiguation page every time you visit OpenWeatherMap
;; via a mouse-3 click on the Weatherline mode lighter.) If you're
;; getting correct weather data, the answer here should probably be
;; "yes"; otherwise, you'll want to visit the OpenWeatherMap page and
;; dig out the correct location ID for your purposes, and set that as
;; the value of `weatherline-location-id'. (If you answer "no",
;; weatherline-mode will quit bothering you about it, and just go on
;; using the value of `weatherline-location'.)

;; Once the mode's been given a location and activated, it will update
;; itself at a customizable interval, so that your weather data stays
;; reasonably fresh. You won't be prevented from setting the interval
;; to zero minutes, but it's not really recommended to do so.

;; This mode is highly customizable; the form of the mode line
;; display, the information there included, and the face in which it's
;; rendered are all entirely under your control. M-x customize-group
;; RET weatherline RET to see what's available in detail.

;; This mode binds no keys; its only map is the one attached to the
;; mode line display. I suppose you could bind something to
;; `weatherline-fetch-update' if you really want to; <mouse-2> on the
;; mode line display is already bound that way. <mouse-3> on the mode
;; line display will open your default browser on the OpenWeatherMap
;; page for your location. (It may misbehave the first time you do
;; this; there seems to be some sort of cookie magic involved
;; there. Nothing I can see to do about that; sorry.)

;; [1] https://github.com/fcambus/ansiweather/blob/master/ansiweather
;; [2] https://news.ycombinator.com/item?id=6587660
;; [3] http://nyan-mode.buildsomethingamazing.com/

;;; Bugs/TODO:

;; I'm not really happy with how this minor mode elbows its way into
;; the mode line, but the method I'm using seems to be the approved
;; one, or at least a fairly common one. If there's interest, I'll add
;; a customization option to have the mode display itself as an
;; ordinary minor mode instead.

;; At some point I intend to add an option controlling whether the
;; mode line lighter appears on all windows' mode lines, or only on
;; the active one. (The option's already here, but commented out, and
;; the mode line display code takes no account of it yet.)

;; This is the second Emacs minor mode I've written from scratch for
;; public release. (The first is not yet publicly available, but once
;; released it will be under the name "dedicate-windows-manually.el"
;; in the same place you found this.) I've been using it for a couple
;; of months without problems, which means there are probably several
;; major bugs in it which I have yet to find. Should you encounter one
;; or more of them, I'd be delighted to receive a pull request with a
;; fix, or failing that, at least an email which takes time out from
;; slandering my ancestry, upbringing, and personal habits to give
;; some details on how to reproduce the bug.

;; The mode line display is inserted immediately after the buffer
;; identification. Depending on how your mode line is set up, this may
;; or may not place it adjacent to your Nyan Cat progress bar.

;;; Miscellany:

;; The canonical version of this file is hosted in my Github
;; repository [4]. If you didn't get it from there, great! I'm happy
;; to hear my humble efforts have achieved wide enough interest to
;; result in a fork hosted somewhere else. I'd be obliged if
;; you'd drop me a line to let me know about it.

;; [4] https://github.com/aaron-em/weatherline.el

;;; Code:

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

(defcustom weatherline-symbols t
  "Whether to use Unicode symbols to display weather
information."
  :group 'weatherline
  :tag "Use symbols?"
  :type '(choice (const :tag "No" nil)
                 (const :tag "Yes" t)))

(defcustom weatherline-indicator-for-day '("☀" "Clear")
  "The Unicode symbol and string to use for a clear day."
  :group 'weatherline
  :tag "Indicator for clear day"
  :type '(list (string :tag "Symbol")
               (string :tag "String")))

(defcustom weatherline-indicator-for-night '("☾" "Clear")
  "The Unicode symbol and string to use for a clear night."
  :group 'weatherline
  :tag "Indicator for clear night"
  :type '(list (string :tag "Symbol")
               (string :tag "String")))

(defcustom weatherline-indicator-for-clouds '("⛅" "Clouds")
  "The Unicode symbol and string to use for cloudy weather."
  :group 'weatherline
  :tag "Indicator for cloudy weather"
  :type '(list (string :tag "Symbol")
               (string :tag "String")))

(defcustom weatherline-indicator-for-rain '("⛈" "Rain")
  "The Unicode symbol and string to use for rainy weather."
  :group 'weatherline
  :tag "Indicator for rainy weather"
  :type '(list (string :tag "Symbol")
               (string :tag "String")))

(defcustom weatherline-lighter-include-sky t
  "Whether to include the sky condition in the Weatherline
lighter string."
  :group 'weatherline
  :tag "Include sky in lighter"
  :set #'(lambda (sym val)
           (if (fboundp 'weatherline-fetch-update) (weatherline-fetch-update))
           (set-default sym val))
  :type '(choice (const :tag "No" nil)
                 (const :tag "Yes" t)))

(defcustom weatherline-lighter-include-temperature t
  "Whether to include the temperature in the Weatherline lighter
string."
  :group 'weatherline
  :tag "Include temperature in lighter"
  :set #'(lambda (sym val)
           (if (fboundp 'weatherline-fetch-update) (weatherline-fetch-update))
           (set-default sym val))
  :type '(choice (const :tag "No" nil)
                 (const :tag "Yes" t)))

(defcustom weatherline-lighter-include-humidity t
  "Whether to include the humidity in the Weatherline lighter
string."
  :group 'weatherline
  :tag "Include humidity in lighter"
  :set #'(lambda (sym val)
           (if (fboundp 'weatherline-fetch-update) (weatherline-fetch-update))
           (set-default sym val))
  :type '(choice (const :tag "No" nil)
                 (const :tag "Yes" t)))

(defcustom weatherline-lighter-include-pressure nil
  "Whether to include the current atmospheric pressure in the
Weatherline lighter string."
  :group 'weatherline
  :tag "Include pressure in lighter"
  :set #'(lambda (sym val)
           (if (fboundp 'weatherline-fetch-update) (weatherline-fetch-update))
           (set-default sym val))
  :type '(choice (const :tag "No" nil)
                 (const :tag "Yes" t)))

;; FIXME implement this
;; (defcustom weatherline-selected-window-only nil
;;   "Whether to show the Weatherline lighter in all windows' mode
;; lines, or only in that of the currently selected window."
;;   :group 'weatherline
;;   :tag "Show in selected window's mode line only"
;;   :type '(choice (const :tag "No" nil)
;;                  (const :tag "Yes" t)))

(defface weatherline-mode-line-face
  `((((class color) (background light))
     (:foreground "black"))
    (((class color) (background dark))
     (:foreground "white"))
    (t (:foreground "black")))
  "Face for mode line weather information display."
  :group 'weatherline
  :tag "Mode line face")

(defface weatherline-mode-line-updating-face
  `((((class color) (background light))
     (:foreground "gray60"))
    (((class color) (background dark))
     (:foreground "gray40"))
    (t (:foreground "gray")))
  "Face used for mode line weather display while an update is in
progress, or to indicate stale data after an update has failed."
  :group 'weatherline
  :tag "Mode line updating face")

(defvar weatherline-face-remap-cookie nil
  "A place to keep the return value from a call to
  `face-remap-add-relative'.")

(defvar weatherline-temperature-indicator "°F"
  "The temperature unit indicator for the currently selected
  system of measurement; see `weatherline-units' to change
  that.

Customizing `weatherline-units' sets this variable automatically,
overwriting whatever value is present; if you set
`weatherline-units' by hand, the magic won't be invoked, and
you'll need to set this by hand too.")

(defvar weatherline-timer nil
  "The value returned by the (latest?) `run-at-time'
  invocation. Changing this by hand is not recommended.")

(defvar weatherline-last-update nil
  "The time at which the last successful update occurred.")

(defvar weatherline-current-conditions nil
  "The latest information retrieved from OpenWeatherMap.")

(defvar weatherline-lighter-string "Loading"
  "The current weather conditions, in a form suitable for display
  in the mode line.")

(defvar weatherline-mode-line-keymap (make-keymap)
  "A keymap for the weatherline-mode mode line entry.")
(define-key weatherline-mode-line-keymap [mode-line mouse-2]
  'weatherline-fetch-update)
(define-key weatherline-mode-line-keymap [mode-line down-mouse-2]
  'ignore)
(define-key weatherline-mode-line-keymap [mode-line mouse-3]
  'weatherline-browse-url)
(define-key weatherline-mode-line-keymap [mode-line down-mouse-3]
  'ignore)

(defvar weatherline-shut-up-about-nil-location nil
  "Whether or not to bother the user about the
  `weatherline-location' variable being unset.")

(defvar weatherline-shut-up-about-nil-location-id nil
  "Whether or not to bother the user about the
  `weatherline-location-id' variable being unset.")

(defun weatherline-mode-line-echo (window object pos)
  "Generate a tooltip for the weatherline mode line entry."
  (concat "Conditions for " weatherline-location 
          " as of " (format-time-string "%H:%M:%S" weatherline-last-update) "\n"
          "mouse-2: Fetch update now" "\n"
          "mouse-3: View in your default browser"))

;; (defvar weatherline-mode-line-entry
;;   '(:eval (and (boundp weatherline-mode) weatherline-mode
;;                (propertize
;;                 (concat " " (replace-regexp-in-string
;;                              "%" "%%"
;;                              weatherline-lighter-string))
;;                 'face 'weatherline-mode-line-face
;;                 'mouse-face 'mode-line-highlight
;;                 'help-echo 'weatherline-mode-line-echo
;;                 'keymap weatherline-mode-line-keymap)))
;;   "The mode line entry for weatherline-mode.")

(defun weatherline-generate-mode-line-entry ()
  "Generate a propertized string suitable for inclusion in the
mode line."
  (and (boundp weatherline-mode) weatherline-mode
       (propertize
        (concat " " (replace-regexp-in-string
                     "%" "%%"
                     weatherline-lighter-string))
        'face 'weatherline-mode-line-face
        'mouse-face 'mode-line-highlight
        'help-echo 'weatherline-mode-line-echo
        'keymap weatherline-mode-line-keymap)))

(defvar weatherline-mode-line-entry
  '(:eval (weatherline-generate-mode-line-entry))
  "The mode line entry for weatherline-mode.")

(defun weatherline-browse-url ()
  (interactive)
  "Open a browser window on the OpenWeatherMap page corresponding
  to the location configured for weatherline-mode."
  (let* ((location-spec (if weatherline-location-id
                            (number-to-string weatherline-location-id)
                          weatherline-location))
         (url-path (if weatherline-location-id
                       (concat "city/" location-spec)
                     (concat "find?q=" location-spec)))
         (url (concat "http://www.openweathermap.org/" url-path)))
    (browse-url url)))

(defun weatherline-url ()
  "Return a URL suitable for retrieving the current location's
OpenWeatherMap API data."
  (format "http://api.openweathermap.org/data/2.5/weather?q=%s&units=%s"
           weatherline-location weatherline-units))

(defun weatherline-retrieve-weather (callback)
  (if (string= "" weatherline-location)
      (and (null weatherline-shut-up-about-nil-location)
           (setq weatherline-shut-up-about-nil-location t)
           (error "location unset; consider M-x customize-variable RET weatherline-location RET"))
    (url-retrieve (weatherline-url)
                  #'(lambda (status callback)
                      (let ((status-code nil)
                            (response nil))
                        (switch-to-buffer (current-buffer))
                        ;; get response status code
                        (goto-char (point-min))
                        (goto-char (+ 9 (point)))
                        (setq status-code (string-to-number
                                           (buffer-substring-no-properties
                                            (point) (+ 3 (point)))))
                        ;; throw, ignoring response body, if we didn't get HTTP 200
                        (if (not (= 200 status-code))
                            (error "server returned status code %d" status-code))
                        ;; get & handle response body
                        (goto-char (point-max))
                        (backward-char 1)
                        (move-beginning-of-line nil)
                        (setq response
                              (json-read-from-string
                               (buffer-substring-no-properties (point) (point-max))))
                        (kill-buffer (current-buffer))
                        (setq weatherline-last-update (current-time))
                        (face-remap-remove-relative weatherline-face-remap-cookie)
                        (funcall callback response)))
                  `(,callback) t)))

(defun weatherline-decompose-response (resp)
  (let* ((now (floor (float-time)))
         ;; unvectorize the 'weather value
         (weather-list (car (append (cdr (assoc 'weather resp)) nil)))
         (sunrise (cdr (assoc 'sunrise (assoc 'sys resp))))
         (sunset (cdr (assoc 'sunset (assoc 'sys resp))))
         (period (if (or (>= now sunset) (<= now sunrise)) 'night 'day)))

    (and (null weatherline-location-id)
         (null weatherline-shut-up-about-nil-location-id)
         weatherline-request-set-location-id
         (if (y-or-n-p "Set Weatherline location ID from API response?")
             (progn 
               (customize-save-variable
                'weatherline-location-id (cdr (assoc 'id resp)))
               (message "Weatherline location ID set and saved."))
           (progn
             (setq weatherline-shut-up-about-nil-location-id t)
             (message "Location ID prompts suppressed for this session."))))

    `((timestamp   . ,now)
      (sky         . ,(cdr (assoc 'main weather-list)))
      (temperature . ,(cdr (assoc 'temp (assoc 'main resp))))
      (city        . ,(cdr (assoc 'name resp)))
      (humidity    . ,(cdr (assoc 'humidity (assoc 'main resp))))
      (pressure    . ,(cdr (assoc 'pressure (assoc 'main resp))))
      (sunrise     . ,sunrise)
      (sunset      . ,sunset)
      (period      . ,period))))

(defun weatherline-update-lighter-string (conditions)
  "Update the mode line summary of current weather conditions."
  (let* ((cond-sym-fun (if weatherline-symbols 'car 'cdr))
         (sky-cond (cdr (assoc 'sky conditions)))
         (sky-cond-sym-list (cond
                             ((string= sky-cond "Rain")
                              weatherline-indicator-for-rain)
                             ((string= sky-cond "Clouds")
                              weatherline-indicator-for-clouds)
                             ((eq (cdr (assoc 'period conditions)) 'night)
                              weatherline-indicator-for-night)
                             (t weatherline-indicator-for-day)))
         (sky-cond-sym (apply cond-sym-fun `(,sky-cond-sym-list))))
    (setq weatherline-lighter-string
          (concat 
           (and weatherline-lighter-include-sky
                (concat (if (listp sky-cond-sym)
                            (car sky-cond-sym)
                          sky-cond-sym) " "))
           (and weatherline-lighter-include-temperature
                (concat (number-to-string
                         (floor (cdr (assoc 'temperature conditions)))) weatherline-temperature-indicator " "))
           (and weatherline-lighter-include-humidity
                (concat (number-to-string
                         (cdr (assoc 'humidity conditions))) "% "))
           (and weatherline-lighter-include-pressure
                (concat (number-to-string
                         (floor (cdr (assoc 'pressure conditions)))) "hPa "))))))

(defun weatherline-fetch-update ()
  "Get current weather information from OpenWeatherMap."
  (interactive)
  (setq weatherline-face-remap-cookie
        (face-remap-add-relative 'weatherline-mode-line-face
                                 'weatherline-mode-line-updating-face))
  (condition-case weatherline-error
      (weatherline-retrieve-weather
       #'(lambda (response)
           (setq weatherline-current-conditions
                 (weatherline-decompose-response response))
           (weatherline-update-lighter-string weatherline-current-conditions)))
    (error (message (concat "Unable to update weatherline: "
                            (cadr weatherline-error))))))

(defun weatherline-kill-timer ()
  "Kill any currently existent timer set to update weather data."
  (and weatherline-timer (cancel-timer weatherline-timer))
  (setq weatherline-timer nil))

(defun weatherline-update-timer ()
  "Set a timer for the next background update of weather data,
  killing any timer which already exists."
  (if weatherline-timer (weatherline-kill-timer))
  (setq weatherline-timer
        (run-at-time weatherline-update-interval nil
                     #'(lambda ()
                         (weatherline-fetch-update)
                         (weatherline-update-timer)))))

(defun weatherline-insert-lighter ()
  "Add the weatherline mode line entry to the mode line, if it's
not already present."
  (or (member weatherline-mode-line-entry mode-line-format)
            (let ((prev-entry (member 'mode-line-buffer-identification
                                      mode-line-format)))
              (setcdr prev-entry (cons weatherline-mode-line-entry
                                       (cdr prev-entry))))))

(defun weatherline-remove-lighter ()
  "Remove from the mode line any extant instances of the
weatherline mode line entry."
  (while (member weatherline-mode-line-entry mode-line-format)
    (setf (car (member weatherline-mode-line-entry mode-line-format)) nil)))

(define-minor-mode weatherline-mode
  "A minor mode to display the current weather in the mode line."
  :init-value nil
  :lighter ""
  :keymap nil
  :global t
  (if weatherline-mode
      (progn
        (weatherline-fetch-update)
        (weatherline-update-timer)
        (weatherline-insert-lighter))
    (progn
      (weatherline-kill-timer)
      (weatherline-remove-lighter)
      (setq weatherline-lighter-string ""))))

(if weatherline-mode (weatherline-mode t))
(provide 'weatherline-mode)

;; weatherline-mode.el ends here.
