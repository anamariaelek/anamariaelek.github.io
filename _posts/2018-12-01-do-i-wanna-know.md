---
title: Do I Wanna Know?
author: Anamaria Elek 
date: 2018-12-01
output: 
  html_document:
  keep_md: true
tags: [R, gganimate]
feature-img: "assets/img/2018-12-01-do-i-wanna-know_files/am.jpg"
---

_How many things would you attempt if you knew you could not fail?_ 

Taking this Robert Frost's verse as a dare, I am attempting to write a blog. It will likely be a collection of most random stuff. It might fail. But it will certainly be about the things that I find terribly cool, and it will certainly _very often_ be about R. The two don't necessarily exclude each other, by the way.  

So given the above stated sentiment, I though I might as well kick the thing off with something completly random. As it happens, 'Do I Wanna Know?' by Arctic Monkeys came up on my Spotify playlist, and the next thing I know --- I've just spent half an hour recrating the album artwork in R. But bear with me, if you will, it is more cool than it sounds at first.  

# Do I Wanna Know?
For those unfamiliar with the said song... come on, how can you _not_ know this song? Now is the perfect time to [google it](http://lmgtfy.com/?q=Do+I+Wanna+Know%3F) and watch the [music video](https://www.youtube.com/watch?v=bpOSxM0rNPM). Then, we'll try and recreate those fancy graphics from the begining of the video, with the iconic sunglasses that also feature on the [AM](https://open.spotify.com/album/78bpIziExqiI9qztvNFlQu) album cover.

# Double Sideband Suppressed Carrier Amplitude Modulation (DSB-SC AM)

My starting point was that this fancy graph must be a combination of sinusoids with changing amplitudes. As usually, some people way more clever than myself have explained it online, and indeed, it is an amplitude modulated sine wave. Precisely, it is a signal produced by the specific __Double Sideband Suppressed Carrier Amplitude Modulation (DSB-SC AM)__.  

OK, word by word.  

_Amplitude modulation_ referes to the fact that the amplitude of a high frequency __carrier signal__ is modulated by a low frequency __baseband signal__.  
_Double sideband_ means that the frequencies produced by amplitude modulation are symmetrically spaced above and below the carrier frequency.  
And _suppressed_ referes to the fact that carrier level is reduced to the lowest practical level (ideally, it is completely suppressed).  
Googling also lets you know that in practice, this is used for shifting the spectra of waves (e.g. sound), which makes it possible to transmit them through antenna of practical dimensions.  

And here's the function that produces the desired signal.  


```r
AMfunction <- function(x,h=20,L=1,l=1,s=0.1,f=0,g=1) {
# baseband - a low frequency signal
E <- function(x,s,f,l) {
s + exp(f*(-1)*x^2/0.4) * (sin(l*x))^2 + 0.35*exp(-1/2*(x/0.4)^2)
}
# carrier - a high frequency sinusoid
H <- function(x,h,L) {
L*cos(h*x)
}
# a small Gaussian to create the elevation for the letter M
G <- function(x) {
exp(-1/2*((x-0.15)/0.1)^2)
}
# by multiplying, low frequency sinusoid becomes the envelope 
# of the high frequency carrier;
# the envelope modulates the amplitude of the carrier;
E(x,s,f,l)*H(x,h,L)*(1-1/2*G(x)*g)+1/6*G(x)*g
}
```

Bam, just like that? There are actually three functions, which I'll break down now.

## Baseband, `E()`

$$E(x) = s + e^{f \cdot \frac{-x^2}{0.4}} \cdot \sin(lx^2) + 0.35 \cdot e^{-\frac{1}{2}\left(\frac{x-0.15}{0.10}\right)^2} $$
  
  `E()` is the baseband, a low frequency signal. It defines the 'outer' range within which the actual signal will be. There are three important parts of the equation:  
  
  * sine is the main part that defines the range for the signal, aka the sunglasses-like pattern, with the $$l$$ setting the frequency value; multiplying the sine wave with gaussian effectively superimposes normal distribution on the sine wave (setting $$f	$$ to 0 precludes this) 

$$e^{f \cdot \frac{-x^2}{0.4}} \cdot \sin(lx^2)$$
  
  * the second element is gaussian that elevates the central part of the sinusoid, aka the AM letters

$$0.35 \cdot e^{-\frac{1}{2}\left(\frac{x-0.15}{0.10}\right)^2}$$
  
  * s defines vertical shift

Here's an example of how changing the aparameters affects the resulting sine wave. For simplicity, the plots are shown without the gaussian that elevates the central part of the sinusoid.  

![]({{ site.baseurl }}/assets/img/2018-12-01-do-i-wanna-know_files/figure-html/unnamed-chunk-2-1.png)<!-- -->

## Carrier, `H()`

$$L \cdot cos(hx)$$

`H()` is the carrier, a high frequency sinusoid. It's frequency is set by $$h$$, and its amplitude by $$L$$. In order to obtain the desired AM artwork, this frequency should be some 20 times the frequency of the baseband.

## Modification, `G()`  

$$G(x) = e^{-\frac{1}{2}\left(\frac{x-0.15}{0.10}\right)^2}$$
  
  `G()` is a small Gaussian that creates the elevation for the letter M in the middle of the graph.  

***
So, back in our `AMfunction()`, these are the parameters you can modify:  
  
* h, the frequency of a high-frequency carrier  
* L, the amplitude  of a high-frequency carrier  
* l, the frequency of a low-frequency baseband  
* s, the vertical shift of a low-frequency baseband  
* f, factor which controls superimosing gaussian to a low-frequncy baseband, setting it to 0 effectively removes any scaling, while setting it to 1 scales the envelope to normal distribution  
* g, factor introduced for scaling the gaussian which makes the M letter in the middle of the graph  

# Plotting the AM graph

Now let's plot our graph for $$x \in [-\pi,\pi]$$, using the default values of parameters.  


```r
x <- runif(10000,-1,1)*pi
y <- AMfunction(x)
df <- data.frame(x=x,y=y)
require(ggplot2)
ggplot(df,aes(x,y)) + 
    geom_line() + 
	theme_void()
```

![]({{ site.baseurl }}/assets/img/2018-12-01-do-i-wanna-know_files/figure-html/unnamed-chunk-3-1.png)<!-- -->

Looking good, eh? The fun part starts now --- lets make it move. The [gganimate](github.com/thomasp85/gganimate) package amazingly revamped by [Thomas Lin Pedersen](https://twitter.com/thomasp85) makes this possible (the package is not yet on CRAN, but you can get it from [GitHub](github.com/thomasp85/gganimate)).  

First, I'll just make the transition between the simple horizontal line at $$y=0$$, and the amplitude modulated sine wave. The `transition_states` and `transition_length` are the required arguments specifying relative length for animation states and transitions between them, respectively.     


```r
df <- data.frame(x=x, y0=0, y1=y)
require(data.table)
df_melted <- melt(df,id.vars="x",measure.vars=c("y0","y1"))
require(gganimate)
am <- ggplot(df_melted,aes(x,value)) +  
    geom_line() +  
    theme_void() +  
    transition_states(variable,transition_length=1,state_length=1)    
animate(am, length=1, width=1000, height=400)
```

![]({{ site.baseurl }}/assets/img/2018-12-01-do-i-wanna-know_files/figure-html/unnamed-chunk-4-1.gif)<!-- -->

Changing the parameters to produce the other type of graph seen in the video.  


```r
y <- AMfunction(x,s=0,l=0.01,L=3,g=0,f=1)
df <- data.frame(x=x, y=y)
ggplot(df, aes(x,y)) + geom_line() + theme_void()
```

![]({{ site.baseurl }}/assets/img/2018-12-01-do-i-wanna-know_files/figure-html/unnamed-chunk-5-1.png)<!-- -->

We can then combine the two AM graphs with simple horizontal line in a single animation.  


```r
df <- data.frame(x=x, y0=0, y1=y, y2=0, y3=AMfunction(x))
df_melted <- melt(df,id.vars="x",measure.vars=c("y0","y1","y2","y3"))
am <- ggplot(df_melted,aes(x,value)) + 
    geom_line() +  
    theme_void() +  
    transition_states(variable,transition_length=1,state_length=0.5)  
animate(am, length=1, width=1000, height=400)
```

![]({{ site.baseurl }}/assets/img/2018-12-01-do-i-wanna-know_files/figure-html/unnamed-chunk-6-1.gif)<!-- -->

Combining the two AM graphs with different simple curves, we can come close to recreating the animations seen in the video. Here's how close I got. I challange you to do better, and share your ideas in the comments below.  

![]({{ site.baseurl }}/assets/img/2018-12-01-do-i-wanna-know_files/figure-html/unnamed-chunk-7-1.gif)<!-- -->

# References

The function I used is modified from the following [Quora answer](https://qr.ae/TUhwlT).  
The animation is brought to you by [gganimate](github.com/thomasp85/gganimate).  
You can read this post --- and many, many more about all things R --- on [R bloggers](https://www.r-bloggers.com/).