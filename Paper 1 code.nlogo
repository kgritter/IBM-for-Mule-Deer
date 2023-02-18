extensions [palette
  gis gis
csv
  rngs
]
globals [
  logistic
  K
cresthills
grass
  ruggtest
  riverstest
  streamstest
  roadstest
  wellstest
  wc250test
  wc2502test
  ag250test
  ed250test
  HRPoints
TF-weight
TM-weight
max-angle
min-angle
csv
row
groups
vonmise
  prob
  winteroutput


]
turtles-own
[ infected?           ;; If true, the person is infected
  susceptible? ;; Tracks whether the person was initially susceptible
  female?
  male?
  angle
  step-length
  result
  point
  leader
  group
  leaderangle
  within-group-winter-same
  between-group-winter-same
  within-group-winter-mixed
  between-group-winter-mixed
  step-within-winter-same
  step-between-winter-same
  step-within-winter-mixed
  step-between-winter-mixed
  HR-Dist
  vm-length
  HRX
  HRY
  Wintergroup
  sine
  cosine
  min-time-since
]

patches-own
[  F-visits
  M-visits
  visits
 deaths
  transmission-rate
  random-n
  centroid
  ID
  Fweight
  Mweight
  proportional-Mweight
  proportional-Fweight
  Females
  Males
  within-contacts-winter-MM
  within-contacts-winter-FF
  within-contacts-winter-MF
  between-contacts-winter-MM
  between-contacts-winter-FF
  between-contacts-winter-MF
  wells
  rivers
  streams
  roads
  wc
  wc2
  edge
  ag
  rugg
  areasumbetween
  areasumwithin
]
;;;
;;; SETUP PROCEDURES
;;;

 to load-gis
  set grass gis:load-dataset "RandomClip.asc"
    set ruggtest gis:load-dataset "ruggtest.asc"
    set ag250test gis:load-dataset "ag250test.asc"
    set ed250test gis:load-dataset "ed250test.asc"
    set riverstest gis:load-dataset "riverstest.asc"
    set roadstest gis:load-dataset "roadstest.asc"
    set streamstest gis:load-dataset "streamstest.asc"
    set wc250test gis:load-dataset "wc250test.asc"
    set wc2502test gis:load-dataset "wc2502test.asc"
    set wellstest gis:load-dataset "wellstest.asc"


  gis:set-world-envelope-ds gis:envelope-of ruggtest
  gis:apply-raster ruggtest rugg
  gis:apply-raster ag250test ag
  gis:apply-raster ed250test edge
  gis:apply-raster riverstest rivers
  gis:apply-raster roadstest roads
  gis:apply-raster streamstest streams
  gis:apply-raster wc250test wc
  gis:apply-raster wc2502test wc2
  gis:apply-raster wellstest wells

end
to total-setup
  setup
  load-gis
end
to setup
  clear-all
  reset-ticks
  random-seed Seed
  load-gis
  file-open "HRPlacementTestSquareSpaced200.csv"
  set csv csv:from-file "HRPlacementTestSquareSpaced200.csv"
  setup-people
  calcweightearlygestation
  rngs:set-seed 1 Seed

end


to setup-people
  create-turtles initial-people
  [    set infected? true
    set susceptible? false
    set female? true
    set male? false

    if random-float 100 > 70
    [set male? true
      set female? false]

    set shape "mule deer"
    set color brown
    set size 10
    set point 0
    set leader false
    ifelse who < (HR-Number - 1) [set group (who + 1)] [
      while [group > HR-Number or group = 0] [set group random 240]]
   setxy (item 3 item group csv) (item 4 item group csv)
    set HRX xcor
    set HRY ycor]
    ;set Summergroup group
   ; switchHR
  ;  set choice 0


  foreach remove-duplicates([group] of turtles) [x -> ask one-of turtle-set (turtles with [group = x]) [set leader true]]
  foreach remove-duplicates([group] of turtles) [x -> ask turtles with [group = x] [set leaderangle one-of (turtle-set (turtles with [(group = x) and leader = true ]))]]

end



to assign-color  ;; turtle procedure
  if infected?
    [ set color red]
  if susceptible?
  [set color brown]

end


;;;
;;; GO PROCEDURES
;;;


to go
  if ticks = 100 [ask turtles [set within-group-winter-mixed 0
    set within-group-winter-same 0
    set between-group-winter-mixed 0
    set between-group-winter-same 0]
    ask patches [set within-contacts-winter-MM 0
      set within-contacts-winter-FF 0
      set within-contacts-winter-MF 0
      set between-contacts-winter-MM 0
      set between-contacts-winter-FF 0
      set between-contacts-winter-MF 0
]]
  if ticks <=  0 [ask turtles [set vm-length .24]]
  if ticks > 0 [
  ask turtles with [HRX = xcor and HRY = ycor] [set vm-length .24]
    foreach remove-duplicates([group] of turtles) [x ->
  ask turtles with [group = x and HRX != xcor and HRY != ycor][
        set vm-length sqrt(((kappa-1 * cos((450 - heading) mod 360)) + (kappa-2 * cos((450 - towardsxy HRX HRY) mod 360 ))) ^ 2 + ((kappa-1 * sin((450 - heading) mod 360)) + (kappa-2 * sin((450 - towardsxy HRX HRY) mod 360))) ^ 2) ] ]]
  ask turtles [
    set result 0
    set leader false]


foreach remove-duplicates([group] of turtles) [x ->
    ask turtles with [group = x and HRX != xcor and ((kappa-1 * sin((450 - heading) mod 360) + (kappa-2 * sin((450 - towardsxy HRX HRY) mod 360))) != 0)] [set sine ((kappa-1 * sin((450 - heading) mod 360)) + (kappa-2 * sin((450 - towardsxy HRX HRY) mod 360)))
    set cosine ((kappa-1 * cos((450 - heading) mod 360)) + (kappa-2 * cos((450 - towardsxy HRX HRY) mod 360)))
    set heading ((450 - atan sine cosine) mod 360)
    set HR-Dist distancexy HRX HRY]]



  foreach remove-duplicates([group] of turtles) [x -> ask one-of turtle-set turtles with [group = x] [set leader true]]


  ask turtles
    [ set result 0
      contactwinter

  ]

   ask patches
    [ set between-contacts-winter-MM between-contacts-winter-MM + sum [step-between-winter-same] of turtles-here with [male? = true]
     set within-contacts-winter-MM within-contacts-winter-MM + sum [step-within-winter-same] of turtles-here with [male? = true]
      set between-contacts-winter-FF between-contacts-winter-FF + sum [step-between-winter-same] of turtles-here with [female? = true]
     set within-contacts-winter-FF within-contacts-winter-FF + sum [step-within-winter-same] of turtles-here with [female? = true]
     set between-contacts-winter-MF between-contacts-winter-MF + sum [step-between-winter-mixed] of turtles-here
     set within-contacts-winter-MF within-contacts-winter-MF + sum [step-within-winter-mixed] of turtles-here]

  ask turtles with [female?]
  [if leader[
      Fmove]]

  ask turtles with [male?] [if leader[
    Mmove]
]
  ask turtles[
   if (not leader) and male?
    [Mmovetoward]
  if (not leader) and female?
    [Fmovetoward]]

  tick

end

 to Mmove
while [result = 0] [
    set angle ((rngs:rnd-vm 1 vm-length) * 180 / pi)
    set step-length ((random-exponential 271) / 30)

      set point ([proportional-Mweight] of patch-right-and-ahead angle step-length)
    if (count turtles-on patch-right-and-ahead angle step-length) > 7
    [set point 0]
    if point > random-float 1 [set result 1]]

  if result = 1
  [rt angle
    fd step-length]
end

to Fmove
while [result = 0] [
    set angle ((rngs:rnd-vm 1 vm-length) * 180 / pi)
    set step-length ((random-exponential 245) / 30)
      set point ([proportional-Fweight] of patch-right-and-ahead angle step-length)
    if (count turtles-on patch-right-and-ahead angle step-length) > 7
    [set point 0]
    if point > random-float 1 [set result 1]]

  if result = 1
  [rt angle
    fd step-length]
end



to Fmovetoward
  foreach remove-duplicates([group] of turtles) [x -> if group = x [ set leaderangle one-of turtle-set turtles with [group = x and leader = true]]]
 while [result = 0] [
    set angle ((rngs:rnd-vm 1 vm-length) * 180 / pi)
    set step-length ((random-exponential 245) / 30)
      set point ([proportional-Fweight] of patch-right-and-ahead angle step-length)
        if (xcor != ([xcor] of leaderangle) or ycor != ([ycor] of leaderangle)) [
      if not (( abs(((heading + angle) mod 360) - (towards leaderangle)) > (360 - Angle-S)) or ( abs(((heading + angle) mod 360) - (towards leaderangle)) < Angle-S)) [set point 0]]
    if (count turtles-on patch-right-and-ahead angle step-length) > 7
    [set point 0]
    if (point > (random-float 1))
    [set result 1]]

if result = 1
    [rt angle
    fd step-length]
end

to Mmovetoward
  foreach remove-duplicates([group] of turtles) [x -> if group = x [ set leaderangle one-of turtle-set turtles with [group = x and leader = true]]]

 while [result = 0] [   set angle ((rngs:rnd-vm 1 vm-length) * 180 / pi)
    set step-length ((random-exponential 271) / 30)
      set point ([proportional-Mweight] of patch-right-and-ahead angle step-length)
    if (xcor != ([xcor] of leaderangle) or ycor != ([ycor] of leaderangle)) [
      if not (((((heading + angle) mod 360) - (towards leaderangle)) mod 360 > (360 - Angle-S)) or ((((heading + angle) mod 360) - (towards leaderangle)) mod 360 < Angle-S)) [set point 0]]
    if (count turtles-on patch-right-and-ahead angle step-length) > 7
    [set point 0]
    if (point > (random-float 1))
    [set result 1]]

if result = 1
    [rt angle
    fd step-length]
end


to contactwinter
if female? [
    let nearby-within-same (turtles in-radius 0.17 with [(group = [group] of myself) and (female? = true)])
  let nearby-between-same (turtles in-radius 0.17 with [(group != [group] of myself) and (female? = true)])
  let nearby-within-mixed (turtles in-radius 0.17 with [(group = [group] of myself) and (female? = false)])
  let nearby-between-mixed (turtles in-radius 0.17 with [(group != [group] of myself) and (female? = false)])

    set within-group-winter-same (within-group-winter-same + count nearby-within-same - 1)
    set between-group-winter-same between-group-winter-same + count nearby-between-same
  set step-within-winter-same (count nearby-within-same - 1)
    set step-between-winter-same count nearby-between-same

      set within-group-winter-mixed (within-group-winter-mixed + count nearby-within-mixed)
    set between-group-winter-mixed between-group-winter-mixed + count nearby-between-mixed
  set step-within-winter-mixed (count nearby-within-mixed)
    set step-between-winter-mixed count nearby-between-mixed]
  if male? [
      let nearby-within-same (turtles in-radius 0.17 with [(group = [group] of myself) and (male? = true)])
    let nearby-between-same (turtles in-radius 0.17 with [(group != [group] of myself) and (male? = true)])
    let nearby-within-mixed (turtles in-radius 0.17 with [(group = [group] of myself) and (male? = false)])
    let nearby-between-mixed (turtles in-radius 0.17 with [(group != [group] of myself) and (male? = false)])



    set within-group-winter-same (within-group-winter-same + count nearby-within-same - 1)
    set between-group-winter-same between-group-winter-same + count nearby-between-same
  set step-within-winter-same (count nearby-within-same - 1)
    set step-between-winter-same count nearby-between-same

        set within-group-winter-mixed (within-group-winter-mixed + count nearby-within-mixed)
    set between-group-winter-mixed between-group-winter-mixed + count nearby-between-mixed
  set step-within-winter-mixed (count nearby-within-mixed)
    set step-between-winter-mixed count nearby-between-mixed]


end

to calcweightearlygestation

    ask patches [set Mweight (exp((-0.69855 * ag) + (0.088469 * edge) + (-0.10359 * rivers) + (-0.16473 * roads) + (0.27848 * rugg) + (-0.11612 * streams) + (-0.72508 * wc) + (0.73434 * wc2) + (-0.03301 * wells) + (-0.11284 * (rivers * rugg))))]
  (set TM-weight max [Mweight] of patches)
  ask patches[
      ( set proportional-Mweight (Mweight / TM-weight))]
  ask patches [set Fweight (exp((-0.30922 * ag) +	(0.068058 * edge) + (-0.05049 * rivers) + (-0.12352 * roads) + (0.247312 * rugg) + (-0.12346 * streams) + (0.459936 * wc)))]
  (set TF-weight max[Fweight] of patches)
  ask patches[
        ( set proportional-Fweight (Fweight / TF-weight))]
end

to-report probability
  report  sum ([proportional-Mweight] of patches) + sum ([proportional-Fweight] of patches)
end
  to-report angle1
  report [angle] of turtle 0
end
to-report Tvisits
  report [visits] of patches
end

to-report leaderangl
  report [towards leaderangle] of turtle 0
end


to-report day
  report ticks mod 4380 / 12
end
to-report points
  report [point] of turtle 0
end
to-report vm-kappa
  report [vm-length] of turtle 0
end

to-report results
  report [result] of turtle 0
end
to-report BetweenWinter
  report (sum [between-group-winter-same] of turtles + sum [between-group-winter-mixed] of turtles)
end
to-report WithinWinter
  report (sum [within-group-winter-same] of turtles + sum [within-group-winter-mixed] of turtles)
end

to-report group-size
  report mean(map [x -> count turtles with [group = x]] remove-duplicates([group] of turtles))
end


to-report between-turtles
 report sum ([between-group-winter-mixed] of turtles) +  sum( [between-group-winter-same] of turtles)
end
  to-report within-turtles
 report sum ([within-group-winter-same] of turtles) + sum([within-group-winter-mixed] of turtles)
end
  to-report between-turtles-list
 report [(list between-group-winter-mixed between-group-winter-same who)] of turtles
end
  to-report within-turtles-list
report [(list within-group-winter-mixed within-group-winter-same who)] of turtles
end

to-report sex
  report [(list male? female? who)] of turtles
end


to-report withinFF
  report sum [within-contacts-winter-FF] of patches
end

to-report withinMF
  report sum [within-contacts-winter-MF] of patches
end

to-report withinMM
  report sum [within-contacts-winter-MM] of patches
end

to-report betweenFF
  report sum [between-contacts-winter-FF] of patches
end

to-report betweenMF
  report sum [between-contacts-winter-MF] of patches
end

to-report betweenMM
  report sum [between-contacts-winter-MM] of patches
end

to store-raster

  gis:store-dataset gis:patch-dataset within-contacts-winter-MM (word "WithinMM " random-float 1.0 ".asc")
  gis:store-dataset gis:patch-dataset within-contacts-winter-MF (word "WithinMF " random-float 1.0 ".asc")
  gis:store-dataset gis:patch-dataset within-contacts-winter-FF (word "WithinFF " random-float 1.0 ".asc")
  gis:store-dataset gis:patch-dataset between-contacts-winter-MM (word "BetweenMM " random-float 1.0 ".asc")
  gis:store-dataset gis:patch-dataset between-contacts-winter-MF (word "BetweenMF " random-float 1.0 ".asc")
  gis:store-dataset gis:patch-dataset between-contacts-winter-FF (word "BetweenFF " random-float 1.0 ".asc")


end

; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
626
10
1899
1284
-1
-1
1.0
1
8
1
1
1
0
1
1
1
-632
632
-632
632
1
1
1
2 Hours
30.0

BUTTON
335
17
418
50
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
425
89
508
122
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
46
14
315
47
initial-people
initial-people
0
1500
1440.0
10
1
NIL
HORIZONTAL

PLOT
296
168
595
318
plot 1
Hours
# of individuals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Females" 1.0 0 -1664597 true "" "plot count turtles with [female?]"
"Males" 1.0 0 -10649926 true "" "plot count turtles with [not female?]"

BUTTON
432
18
506
51
NIL
load-gis
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
519
18
611
51
total setup
random-seed 15\nsetup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
135
145
206
190
NIL
probability
17
1
11

MONITOR
44
142
115
187
NIL
TM-weight
17
1
11

MONITOR
45
199
114
244
NIL
TF-weight
17
1
11

MONITOR
213
83
270
128
NIL
day
17
1
11

MONITOR
46
82
103
127
NIL
results
17
1
11

MONITOR
127
83
184
128
NIL
points
17
1
11

MONITOR
37
321
108
366
NIL
leaderangl
17
1
11

MONITOR
37
262
125
307
NIL
angle1
17
1
11

MONITOR
35
387
145
432
NIL
BetweenWinter
17
1
11

MONITOR
159
388
251
433
NIL
WithinWinter
17
1
11

MONITOR
138
318
205
363
NIL
vm-kappa
17
1
11

MONITOR
136
200
217
245
NIL
group-size
17
1
11

PLOT
311
511
597
691
plot 2
NIL
NIL
0.0
13.0
0.0
45.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 true "set-histogram-num-bars 12\n" "histogram (map [x -> count turtles with [Wintergroup = x]] remove-duplicates([Wintergroup] of turtles))"

SLIDER
31
446
203
479
kappa-2
kappa-2
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
32
509
204
542
kappa-1
kappa-1
0
1
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
32
566
204
599
Angle-S
Angle-S
15
180
30.0
15
1
NIL
HORIZONTAL

SLIDER
31
630
203
663
HR-Number
HR-Number
100
240
218.0
10
1
NIL
HORIZONTAL

SLIDER
32
693
204
726
Seed
Seed
11
15
11.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model simulates the spread of an infectious disease in a closed population. It is an introductory model in the curricular unit called epiDEM (Epidemiology: Understanding Disease Dynamics and Emergence through Modeling). This particular model is formulated based on a mathematical model that describes the systemic dynamics of a phenomenon that emerges when one infected person is introduced in a wholly susceptible population. This basic model, in mathematical epidemiology, is known as the Kermack-McKendrick model.

The Kermack-McKendrick model assumes a closed population, meaning there are no births, deaths, or travel into or out of the population. It also assumes that there is homogeneous mixing, in that each person in the world has the same chance of interacting with any other person within the world. In terms of the virus, the model assumes that there are no latent or dormant periods, nor a chance of viral mutation.

Because this model is so simplistic in nature, it facilitates mathematical analyses and also the calculation of the threshold at which an epidemic is expected to occur. We call this the reproduction number, and denote it as R_0. Simply, R_0 stands for the number of secondary infections that arise as a result of introducing one infected person in a wholly susceptible population, over the course of the infected person's contagious period (i.e. while the person is infective, which, in this model, is from the beginning of infection until recovery).

This model incorporates all of the above assumptions, but each individual has a 5% chance of being initialized as infected. This model shows the disease spread as a phenomenon with an element of stochasticity. Small perturbations in the parameters included here can in fact lead to different final outcomes.

Overall, this model helps users
1) engage in a new way of viewing/modeling epidemics that is more personable and relatable
2) understand how the reproduction number, R_0, represents the threshold for an epidemic
3) think about different ways to calculate R_0, and the strengths and weaknesses in each approach
4) understand the relationship between derivatives and integrals, represented simply as rates and cumulative number of cases, and
5) provide opportunities to extend or change the model to include some properties of a disease that interest users the most.

## HOW IT WORKS

Individuals wander around the world in random motion. Upon coming into contact with an infected person, by being in any of the eight surrounding neighbors of the infected person or in the same location, an uninfected individual has a chance of contracting the illness. The user sets the number of people in the world, as well as the probability of contracting the disease.

An infected person has a probability of recovering after reaching their recovery time period, which is also set by the user. The recovery time of each individual is determined by pulling from an approximately normal distribution with a mean of the average recovery time set by the user.

The colors of the individuals indicate the state of their health. Three colors are used: white individuals are uninfected, red individuals are infected, green individuals are recovered. Once recovered, the individual is permanently immune to the virus.

The graph INFECTION AND RECOVERY RATES shows the rate of change of the cumulative infected and recovered in the population. It tracks the average number of secondary infections and recoveries per tick. The reproduction number is calculated under different assumptions than those of the Kermack McKendrick model, as we allow for more than one infected individual in the population, and introduce aforementioned variables.

At the end of the simulation, the R_0 reflects the estimate of the reproduction number, the final size relation that indicates whether there will be (or there was, in the model sense) an epidemic. This again closely follows the mathematical derivation that R_0 = beta*S(0)/ gamma = N*ln(S(0) / S(t)) / (N - S(t)), where N is the total population, S(0) is the initial number of susceptibles, and S(t) is the total number of susceptibles at time t. In this model, the R_0 estimate is the number of secondary infections that arise for an average infected individual over the course of the person's infected period.

## HOW TO USE IT

The SETUP button creates individuals according to the parameter values chosen by the user. Each individual has a 5% chance of being initialized as infected. Once the model has been setup, push the GO button to run the model. GO starts the model and runs it continuously until GO is pushed again.

Note that in this model each time-step can be considered to be in hours, although any suitable time unit will do.

What follows is a summary of the sliders in the model.

INITIAL-PEOPLE (initialized to vary between 50 - 400): The total number of individuals in the simulation, determined by the user.
INFECTION-CHANCE (10 - 100): Probability of disease transmission from one individual to another.
RECOVERY-CHANCE (10 - 100): Probability of an infected individual to recover once the infection has lasted longer than the person's recovery time.
AVERAGE-RECOVERY-TIME (50 - 300): The time it takes for an individual to recover on average. The actual individual's recovery time is pulled from a normal distribution centered around the AVERAGE-RECOVERY-TIME at its mean, with a standard deviation of a quarter of the AVERAGE-RECOVERY-TIME. Each time-step can be considered to be in hours, although any suitable time unit will do.

A number of graphs are also plotted in this model.

CUMULATIVE INFECTED AND RECOVERED: This plots the total percentage of infected and recovered individuals over the course of the disease spread.
POPULATIONS: This plots the total number of people with or without the flu over time.
INFECTION AND RECOVERY RATES: This plots the estimated rates at which the disease is spreading. BetaN is the rate at which the cumulative infected changes, and Gamma rate at which the cumulative recovered changes.
R_0: This is an estimate of the reproduction number, only comparable to the Kermack McKendrick's definition if the initial number of infected were 1.

## THINGS TO NOTICE

As with many epidemiological models, the number of people becoming infected over time, in the event of an epidemic, traces out an "S-curve." It is called an S-curve because it is shaped like a sideways S. By changing the values of the parameters using the slider, try to see what kinds of changes make the S curve stretch or shrink.

Whenever there's a spread of the disease that reaches most of the population, we say that there was an epidemic. As mentioned before, the reproduction number indicates the number of secondary infections that arise as a result of introducing one infected person in a totally susceptible population, over the course of the infected person's contagious period (i.e. while the person is infected). If it is greater than 1, an epidemic occurs. If it is less than 1, then it is likely that the disease spread will stop short, and we call this an endemic.

## THINGS TO TRY

Try running the model by varying one slider at a time. For example:
How does increasing the number of initial people affect the disease spread?
How does increasing the recovery chance the shape of the graphs? What about changes to average recovery time? Or the infection rate?

What happens to the shape of the graphs as you increase the recovery chance and decrease the recovery time? Vice versa?

Notice the graph Cumulative Infected and Recovered, and Infection and Recovery Rates. What are the relationships between the two? Why is the latter graph jagged?

## EXTENDING THE MODEL

Try to change the behavior of the people once they are infected. For example, once infected, the individual might move slower, have fewer contacts, isolate him or herself etc. Try to think about how you would introduce such a variable.

In this model, we also assume that the population is closed. Can you think of ways to include demographic variables such as births, deaths, and travel to mirror more of the complexities that surround the nature of epidemic research?

## NETLOGO FEATURES

Notice that each agent pulls from a truncated normal distribution, centered around the AVERAGE-RECOVERY-TIME set by the user. This is to account for the variation in genetic differences and the immune system functions of individuals.

Notice that R_0 calculated in this model is a numerical estimate to the analytic R_0. In the special case of one infective introduced to a wholly susceptible population (i.e., the Kermack-McKendrick assumptions), the numerical estimations of R0 are very close to the analytic values.

## RELATED MODELS

HIV, Virus and Virus on a Network are related models.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Yang, C. and Wilensky, U. (2011).  NetLogo epiDEM Basic model.  http://ccl.northwestern.edu/netlogo/models/epiDEMBasic.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Yang, C. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

moose
false
0
Polygon -7500403 true true 196 228 198 297 180 297 178 244 166 213 136 213 106 213 79 227 73 259 50 257 49 229 38 197 26 168 26 137 46 120 101 122 147 102 181 111 217 121 256 136 294 151 286 169 256 169 241 198 211 188
Polygon -7500403 true true 74 258 87 299 63 297 49 256
Polygon -7500403 true true 25 135 15 186 10 200 23 217 25 188 35 141
Polygon -7500403 true true 270 150 253 100 231 94 213 100 208 135
Polygon -7500403 true true 225 120 204 66 207 29 185 56 178 27 171 59 150 45 165 90
Polygon -7500403 true true 225 120 249 61 241 31 265 56 272 27 280 59 300 45 285 90

mule deer
false
3
Polygon -6459832 true true 30 195 45 225 45 255 45 270 45 285 60 285 60 255 60 210 45 195 30 180 30 180 30 195
Polygon -6459832 true true 196 228 198 297 180 297 178 244 166 213 136 213 106 213 75 210 73 259 50 257 49 229 38 197 26 168 26 137 46 120 101 122 150 120 180 120 210 105 240 105 285 120 270 150 255 150 225 150 195 180
Polygon -6459832 true true 74 258 87 299 63 297 49 256
Polygon -1 true false 25 135 15 186 10 200 15 210 25 188 35 141
Polygon -6459832 true true 270 120 255 105 240 90 225 90 208 105
Polygon -16777216 true false 15 180 15 186 10 200 15 210 25 188 15 180
Polygon -1 true false 30 135 45 150 45 165 30 180 30 180 30 135
Polygon -1 true false 195 75 195 90 210 105 225 105 225 90 210 75 195 75
Polygon -6459832 false true 195 75 195 90 210 105 225 105 225 90 210 75 195 75
Polygon -16777216 false false 60 285 45 255 45 225 30 195 45 225 45 255 60 285 60 300 60 300
Rectangle -16777216 true false 165 225 150 285
Rectangle -6459832 true true 165 195 180 285
Polygon -6459832 false true 180 285 180 270 180 255 180 240 180 225 180 210 180 225 180 240 180 255 180 255 180 270 180 285
Line -6459832 true 180 285 180 285
Line -6459832 true 180 225 180 225
Line -16777216 false 180 210 180 285
Polygon -1 true false 225 90 210 75 195 60 195 45 210 60 225 45 225 60 225 75 240 75 240 45 255 60 270 45 270 60 255 75 240 90 225 90

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rabbit
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
