weatherline.el
==============

Current weather in your Emacs mode line.

Copyright (C) 2013 Aaron Miller. All rights reversed.
Share and Enjoy!

Last revision: Monday, November 4, 2013, ca. 12:30pm.

Author: Aaron Miller <me@aaron-miller.me>

weatherline-mode.el is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2, or
(at your option) any later version.

weatherline-mode.el is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

Commentary
----------

A little while ago, a Bash script called ['ansiweather'][1] turned
up on Hacker News. It's a cute little tool which retrieves weather
data for a given location from the OpenWeatherMap.org API, and
renders it in a colorful format in your terminal.

In the Hacker News comments, [someone said][2] this: "I need this as
an emacs extension. Would fit right next to my [nyan cat progress
bar][3]."

"Why," I thought, "I can do that! It'll be an interesting
exercise." Indeed it was. I now know a great deal about the Emacs
customization interface, mode line display, and HTTP client
library; this pleases me. Perhaps the result of these explorations
will please you too.

To use weatherline-mode, drop this file into your Emacs load path,
then (require 'weatherline-mode). Before invoking the mode, you'll
probably want to set a location for which to receive weather data;
by default, none is set. Do this via M-x customize-group RET
weatherline RET and setting the "Location" variable
('weatherline-location'); the required form for location values is
given in the variable documentation, along with a link to
OpenWeatherMap.org should you desire to investigate further.

Once that's done, along with any other customizations you'd like to
make, M-x weatherline-mode will enable the mode line display and
fetch the current weather data. (If you forget to set a location
before enabling the mode, never fear; it will notice and suggest a
course of action, and decline further to bother you on the subject
until you've given it enough information to start doing its job.)

OpenWeatherMap uses numeric location IDs in addition to textual
search strings; a given search string (e.g. "Baltimore,US") might
map to more than one numeric ID. On the OpenWeatherMap webpage,
this results in a disambiguation page; in an API request, it
appears that the likeliest location is automatically chosen, for
some value of 'likeliest' which might include IP geolocation but
probably just relies on relative size.

If you already know your location's numeric ID, you can supply it
as the value for 'weatherline-location-id'. Otherwise, the first
successful API request will elicit a prompt asking whether you'd
like to use the included location ID in links to the OpenWeatherMap
webpage for your current location. (This avoids the need to go
through a disambiguation page every time you visit OpenWeatherMap
via a mouse-3 click on the Weatherline mode lighter.) If you're
getting correct weather data, the answer here should probably be
"yes"; otherwise, you'll want to visit the OpenWeatherMap page and
dig out the correct location ID for your purposes, and set that as
the value of 'weatherline-location-id'. (If you answer "no",
weatherline-mode will quit bothering you about it, and just go on
using the value of 'weatherline-location'.)

Once the mode's been given a location and activated, it will update
itself at a customizable interval, so that your weather data stays
reasonably fresh. You won't be prevented from setting the interval
to zero minutes, but it's not really recommended to do so.

This mode is highly customizable; the form of the mode line
display, the information there included, and the face in which it's
rendered are all entirely under your control. M-x customize-group
RET weatherline RET to see what's available in detail.

This mode binds no keys; its only map is the one attached to the
mode line display. I suppose you could bind something to
'weatherline-fetch-update' if you really want to; <mouse-2> on the
mode line display is already bound that way. <mouse-3> on the mode
line display will open your default browser on the OpenWeatherMap
page for your location. (It may misbehave the first time you do
this; there seems to be some sort of cookie magic involved
there. Nothing I can see to do about that; sorry.)

[1] https://github.com/fcambus/ansiweather/blob/master/ansiweather
[2] https://news.ycombinator.com/item?id=6587660
[3] http://nyan-mode.buildsomethingamazing.com/

Bugs/TODO
---------

I'm not really happy with how this minor mode elbows its way into
the mode line, but the method I'm using seems to be the approved
one, or at least a fairly common one. If there's interest, I'll add
a customization option to have the mode display itself as an
ordinary minor mode instead.

At some point I intend to add an option controlling whether the
mode line lighter appears on all windows' mode lines, or only on
the active one. (The option's already here, but commented out, and
the mode line display code takes no account of it yet.)

This is the second Emacs minor mode I've written from scratch for
public release. (The first is not yet publicly available, but once
released it will be under the name "dedicate-windows-manually.el"
in the same place you found this.) I've been using it for a week
and a half or so without problems, which means there are certainly
several major bugs in it which I have yet to find. Should you
encounter one or more of them, I'd be delighted to receive a pull
request with a fix, or failing that, at least an email which takes
time out from slandering my ancestry, upbringing, and personal
habits to give some details on how to reproduce the bug.

The mode line display is inserted immediately after the buffer
identification. Depending on how your mode line is set up, this may
or may not place it adjacent to your Nyan Cat progress bar.

Miscellany
----------

The canonical version of this file is hosted in
[my Github repository][4]. If you didn't get it from there, great! I'm
happy to hear my humble efforts have achieved wide enough interest to
result in a fork hosted somewhere else. I'd be obliged if you'd drop
me a line to let me know about it.

[4] https://github.com/aaron-em/weatherline.el
