################################################################################
#### SET-UP #####
################################################################################
library(tidyverse)

my.gentime <- 3.5
my.mutrate.gen <- 1.64e-8
my.mutrate.year <- my.mutrate.gen / my.gentime
my.m.scale <- 1000
my.tautheta.scale <- 0.0001

old.mutrate.gen <- 0.85e-8
old.gentime <- 3.75
old.mutrate.year <- old.mutrate.gen / old.gentime

## Conversion functions:
get.t <- function(tau, t.scale = 1000,
                  tautheta.scale = my.tautheta.scale, mutrate.year = my.mutrate.year) {
  round(((tau * tautheta.scale) / (mutrate.year)) / t.scale) # t in ky
}
get.tau <- function(t, t.scale = 1000,
                    tautheta.scale = my.tautheta.scale, mutrate.year = my.mutrate.year) {
  ((t * mutrate.year) / tautheta.scale) * t.scale # t in ky
}
get.ne <- function(theta, ne.scale = 1000,
                   tautheta.scale = my.tautheta.scale, mutrate.gen = my.mutrate.gen) {
  round((theta * tautheta.scale) / (4 * mutrate.gen) / ne.scale) # Ne in 1000s
}
get.theta <- function(ne, ne.scale = 1000,
                      tautheta.scale = my.tautheta.scale, mutrate.gen = my.mutrate.gen) {
  ((ne * 4 * mutrate.gen) / tautheta.scale) * ne.scale # Ne in 1000s
}


################################################################################
##### DIVTIME AND NE #####
################################################################################
get.ne(theta = 129, ne.scale = 1000) # murW = 197
get.ne(theta = 8, ne.scale = 1000) # murC = 12
get.ne(theta = 3, ne.scale = 1000) # murE = 5
get.ne(theta = 10.4, ne.scale = 1000) # griC = 16
get.ne(theta = 82, ne.scale = 1000) # griC = 125
get.t(tau = 1.1, t.scale = 1000) # gri = 23
get.t(tau = 0.4, t.scale = 1000) # murSE = 9
get.t(tau = 9.9, t.scale = 1000) # murSE = 211
get.t(tau = 26.8, t.scale = 1000) # root = 572

get.ne(theta = 10, ne.scale = 1)

get.t(tau = 6, t.scale = 1)


################################################################################
#### NUMBER OF MIGRANTS #####
################################################################################
m * conversion * mutrate.gen * popsize.target
(2 * 1000) * mutrate.gen * 2000

M = m * conversion * (theta.target / 4) # SysBio paper
((2 * 1000) * mutrate.gen) * (1000/4)

m.scale <- 1000; tautheta.scale = 0.0001
# msx × θx/4 = Msx # http://www.bioone.org/doi/full/10.1642/AUK-15-232.1
# Migration rates were calculated with the migration rate per generation parameter (msx × θx/4 = Msx),
# which is the proportion of individuals  in population x that arrived by migration from population s per generation.
m_gal2fus <- 4
th_fus <- 3
(m_gal2fus * m.scale) * ((th_fus * tautheta.scale) / 4) # 0.3 ?? See below this is the ABSOLUTE NUMBER per generation

# Total mig-rate:
lifespan <- 0.3 # Cfus
(m_gal2fus * m.scale) * (lifespan * tautheta.scale) # 0.12

# Specifically, each migration band S → T is associated with
# a rate parameter m ST , which is a mutation-scaled version of an instantaneous migration rate M ST , with
# m ST = M μ ST . M ST is defined as the proportion of individuals in population T that arose by migration from
# population S per generation.
# So, m = M/u --> M = m*u
prop_gen <- (m_gal2fus * m.scale) * mutrate.gen # proportion per generation
n_gens <- (lifespan * tautheta.scale) / mutrate.gen # number of generations
prop_total <- prop_gen * n_gens # 0.12 = total migration rate
popsize <- (th_fus * tautheta.scale) / (4 * mutrate.gen)
prop_gen * popsize # 0.3 = number per generation
(m_gal2fus * m.scale) * (th_fus * tautheta.scale) / 4


################################################################################
##### ALPHA AND BETA PRIORS #####
################################################################################
alpha = 0.002; beta = 0.00001
curve(dgamma(x, shape = alpha, rate = beta), from = 0, to = 1)
qgamma(c(0.025, 0.975), shape = alpha, rate = beta)
get.mean(alpha, beta, 1)

#library(invgamma)
#a = 1; b = 1/500
#curve(dinvgamma(x, a, b), from = 0, to = 0.01)
#qinvgamma(c(0.025, 0.975), a, b)

# conversion="tau-theta-print" parameter
# beta=rate parameter
# mean=alpha/beta (smaller beta = larger mean), variance = alpha/B^2 ()
get.beta <- function(mean, alpha = 1, conversion = 10000) {
  alpha / (mean / conversion)
}

get.mean <- function(alpha, beta, conversion = 10000) {
  (alpha / beta) * conversion
}

## Beta priors for tau:
get.beta(get.tau(10), 1, 10000) # 10 ky: beta = 10,000
get.beta(get.tau(100), 1, 10000) # 100 ky: beta = 1,000
get.beta(get.tau(1000), 1, 10000) # 1My: beta = 100

get.mean(1, 1000) %>% get.t()
get.t(40)

## Beta prior for theta:
get.beta(get.theta(100), 1, 10000)
get.beta(get.theta(25), 1, 10000)


# den <- density(rgamma(100000, shape = 1, rate = 5))
# dat <- data.frame(x = den$x, y = den$y)
# ggplot(dat, aes(x = x, y = y)) + geom_line(size = 2) + theme_classic() #+ xlim(0, 10000)
# dat$x[which(dat$y == max(dat$y))] * 100000
# mean(dat$x) * 10000
