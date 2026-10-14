---
title: 'Learning Forest Follies'
date: '2026-10-12T09:00:00+02:00'
description: 'A small beginning, and a place to keep the things worth remembering.'
cover: '/images/cover.png'
coverAlt: 'Cuphead shooting at enemies in Forest Follies.'
enemyBackground: true
---


## Motivation
I've recently been taking a course on advanced topics in machine learning, and deep reinforcement learning was the topic that caught my attention most. I was particularly impressed by the Atari experiments: an agent could learn to play directly from screen pixels and even outperform a human expert in some games.[^mnih2013]

That left me wondering how these methods would perform in a more recent game. What would change if the agent had access to in-game data, such as player positions and nearby enemies, rather than visual frames? And how much compute would it take to train an agent that could play better than the average human?

## Background
Before diving into this problem, it is helpful to establish some mathematical foundations underlying reinforcement learning.

A central relationship in reinforcement learning is the **Bellman expectation equation**. For a policy \(\pi\) in a Markov decision process, it states:

$$
V^\pi(s) = \mathbb{E}_\pi\left[R_{t+1} + \gamma V^\pi(S_{t+1}) \mid S_t = s\right].
$$

Here, \(V^\pi(s)\) is the expected discounted total future reward from state \(s\) when following policy \(\pi\). \(R_{t+1}\) is the reward from the next transition, \(S_{t+1}\) is the next state, and \(\gamma\) is the discount factor, which controls how much future rewards count. The expectation averages over the policy's choice of action and the environment's possible next states. Terminal states have zero future value.

In words, a state's value is its expected immediate reward plus the discounted value of what comes next. This recursive relationship connects an action's immediate consequences with its longer-term outcome.

Reinforcement learning is about learning through interaction. An agent observes its environment, chooses an action, and receives a reward along with a new observation. By repeating this process, it tries to learn a *policy*: a rule for deciding what to do in a given situation.

The objective is to maximize the expected total reward over time, rather than just the reward from the next action. In Cuphead, a jump might not provide any immediate reward, but it could prevent a death a few moments later. Learning which actions contribute to a good outcome, even when that outcome is delayed, is a central challenge.

Different reinforcement learning algorithms approach this objective in different ways. Some learn how valuable states or actions are and use those estimates to choose actions. Others adjust the policy directly. Two useful ideas for understanding these approaches are generalized policy iteration and policy gradient methods.

### Generalized Policy Iteration

Generalized policy iteration describes the interaction between two processes: *policy evaluation* and *policy improvement*. Evaluation estimates the expected future reward under the current policy, whose values satisfy the Bellman expectation equation above. Improvement changes the policy to favor actions that appear more valuable. As the policy changes, its value estimates need updating, and the cycle continues.

These processes do not need to finish before the other begins. An agent can update an estimate from a small amount of experience and immediately use it to adjust its behavior. Generalized policy iteration is a broad framework for this interaction, rather than one specific algorithm.

For example, an action-value function, written as \(Q(s,a)\), estimates the expected return from taking action \(a\) in state \(s\) and then following a policy. In Cuphead, it could help compare jumping, shooting, or moving forward. Methods such as SARSA and Q-learning use action-value estimates to guide behavior.

### Policy Gradient Methods

Policy gradient methods learn a parameterized policy directly. A neural network can represent \(\pi_\theta(a\mid s)\): the probability of choosing action \(a\) in state \(s\), with \(\theta\) denoting the network's parameters. Training estimates how changing those parameters would affect expected return and updates them in a direction intended to improve it.

Intuitively, actions followed by better-than-expected outcomes become more likely in similar situations. REINFORCE estimates updates using sampled episode returns. A learned baseline can reduce the noise in those estimates. PPO is another policy optimization method, designed to discourage overly large policy changes during an update.

These ideas overlap. Actor–critic methods learn both a policy—the *actor*—and a value estimate—the *critic*. The critic helps evaluate behavior, while the actor uses that feedback to improve the policy. This connects direct policy optimization with the evaluation-and-improvement perspective of generalized policy iteration.

## The Setup
Cuphead is a 2D action game known for its hand-drawn animation, inspired by cartoons from the 1930s, and its demanding difficulty. Players control a small cartoon character who must dodge attacks, jump over obstacles, and shoot enemies while avoiding damage.

{{< figure src="/images/forest-follies-enemies.png" alt="Forest Follies enemies from the death screen" caption="Forest Follies enemy artwork from Cuphead's death screen." >}}
Forest Follies is Cuphead’s first run-and-gun level. Unlike a boss fight, the goal is to move through the level and reach the exit while surviving enemies, obstacles, and gaps along the way.
For an agent, this requires more than simply moving right and shooting. It needs to time its jumps, react to nearby threats, and sometimes choose between attacking an enemy and avoiding it. 
I chose this level to give the project a concrete starting point: learn to reach the end alive.

The algorithm of choice was **Proximal Policy Optimization (PPO)**, an actor–critic method that learns a policy alongside a value function. The policy chooses actions from the numeric game observations, while the value function helps estimate how promising each situation is. PPO discourages overly large policy changes during training updates.

## Defining the States

One of the things I wanted to explore was what would happen if the agent could read information directly from the game. Learning from screen pixels had produced impressive results in Atari, but using structured game data in Cuphead felt like a less explored experiment. I was curious whether it might lead to something surprising: faster learning, unusually precise play, or strategies I would never think to try myself.

To try this, I exposed numeric information through a C# plugin. Instead of an image, the agent receives a vector describing the player and its surroundings. It gets access to information a human would normally have to infer visually, such as positions, velocities, and enemy health. I wanted to see how far it could get with that advantage—and whether any unexpected behavior would emerge along the way.

The observation encoder produces **294 values** at each decision:

| Information | Number of values | Examples |
| --- | ---: | --- |
| Player and episode context | 26 | Position, velocity, health, jump and dash states, held controls, distance to the exit, and elapsed time |
| Nearby enemies | 96 | Up to 8 enemies, with 12 values per enemy |
| Nearby threats | 144 | Up to 12 projectiles or damaging explosions, with 12 values per threat |
| Terrain probes | 26 | 13 raycasts, each reporting whether it hit terrain and the normalized hit distance |
| Charge weapon | 2 | Charge progress and whether a charged shot is ready |

For enemies and threats, positions are expressed relative to the player. This describes where a danger is in relation to Cuphead, rather than only where it sits in the level. Each object also has features such as estimated velocity, collision-box dimensions, type, and whether it can be parried. Enemy entries include health. Objects are ordered by distance, with a limited number of slots and a fixed detection radius. Empty slots are filled with zeros and have a presence flag of zero, so the input always has the same size.

The terrain probes give the agent a simple geometric view of its surroundings. Downward rays sample the ground at several horizontal offsets, while other rays check for obstacles to either side and overhead. For example, a downward probe finding no ground ahead can provide a cue that a gap is approaching.

I also scale positions, velocities, distances, and other quantities before passing them to the network, and clip selected features. This keeps values with very different units on more comparable scales. Velocity matters because the same position can require different actions depending on whether Cuphead is rising, falling, or standing still. The encoder estimates motion from changes between observations.

Although I refer to this vector as the *state*, it is more precisely an **observation** of the game. It leaves out distant objects and some internal game logic, so I cannot assume it fully satisfies the Markov property used in the background section. Choosing this representation is therefore part of the experiment: the agent needs enough information to make useful decisions, but more inputs alone do not guarantee better learning.

## Defining the Reward (Attempt #1)

My initial approach rewarded forward progress and penalized failure. Focusing on those two terms:

$$
r_t \approx 10\,\Delta p_{\max} - 100\,\mathbf{1}_{\text{failure}}.
$$

Here, \(\Delta p_{\max}\) is newly reached distance as a fraction of the level length, and the failure indicator is one only on the transition that ends an unsuccessful episode. This omits the original time cost, which was refunded on failure. Progress could earn up to 10 points, while failure cost 100. The balance was poor: even a much better attempt still ended with a large negative return if it died.

## Defining the Reward (Attempt #2)

I also tried combining progress, health, and time:

$$
r_t = \beta\,\Delta p_{\max}
    + \lambda\,\Delta HP
    - \theta\,\Delta t.
$$

Here, \(\Delta p_{\max}\) is the increase in furthest distance reached, \(\Delta HP = HP_{t+1}-HP_t\), and \(\Delta t\) is elapsed game time. The scaling factors are absorbed into the coefficients. The agent earned credit for reaching new ground, lost credit for taking damage, and paid a cost for elapsed time. Revisiting the same ground earned nothing. The challenge was balancing the three terms, and there was no separate completion bonus.

## Defining the Reward (Attempt #3)

While thinking about how to improve the reward, I came across an excellent paper by Ng, Harada, and Russell on *potential-based reward shaping*.[^ng1999] It gave me a more principled way to think about progress feedback. The idea is to assign a potential \(\Phi(s)\) to each state and add a reward based on how that potential changes:

$$
F(s_t,s_{t+1}) = \gamma\Phi(s_{t+1})-\Phi(s_t).
$$

I used normalized horizontal position as the potential, giving the agent feedback as it moved through the level. The discount \(\gamma\) matches the learner's discount. I combined this shaping term with a completion bonus, a health-loss penalty, and feedback for confirmed shot hits and misses:

$$
r_t = \alpha\,\mathbf{1}_{\text{completion}}
    - \lambda\,\Delta HP_{\text{lost}}
    + \rho\sum_{j\in\mathcal{S}_t} h_j
    + \beta\left(\gamma\Phi(s_{t+1})-\Phi(s_t)\right).
$$

For each shot \(j\), the hit reward is:

$$
h_j =
\begin{cases}
+1, & \text{if the shot hits at least one enemy},\\
-1, & \text{if the shot ends without hitting any enemy}.
\end{cases}
$$

Here, \(\mathcal{S}_t\) contains shots whose outcomes are newly confirmed at decision \(t\). Each shot is counted once, so hitting multiple enemies still earns only +1. Shots with unresolved outcomes are excluded. Completion required the game's actual win event. The potential \(\Phi\) was normalized horizontal position, with its actual value retained at termination. This supplied feedback about movement, survival, and combat, but left another question: how much should each component matter?

## Tuning the weights

The problem now became finding the right values for four weights:

- \(\alpha\): the reward for completing the level.
- \(\lambda\): the penalty for losing health.
- \(\rho\): the weight of the per-shot +1/−1 hit reward.
- \(\beta\): the strength of potential-based progress shaping.

A large progress weight could make moving forward dominate the reward, while a large health penalty could make risky actions expensive. There was no obvious choice that would balance all four components. I explored two approaches: Bayesian optimisation and LLM assistance.

For Bayesian optimisation, I used Optuna's Tree-structured Parzen Estimator (TPE) to propose weight combinations based on previous trial results. Each combination was used to train an agent, which was then evaluated in the game. The search targeted mean final progress to distinguish candidates when none could finish. The search objective was separate from the reward the agent received during training.

LLM assistance offered a more interactive approach: reviewing the reward design and experiment results, suggesting weight changes, and helping decide what to test next. Those suggestions still needed to be checked through actual training and evaluation. The interesting question was whether this feedback could help find promising settings alongside the automated search. 

## Results
The agent was trained for 500,000 steps, then evaluated using a greedy policy, choosing the action with the highest probability at each decision.

### Manually chosen weights

The video below shows the agent playing with reward weights I chose myself. It was clearly favoring forward progress over preserving HP, pushing ahead even at the cost of taking damage. At this point, it was hard stuck: it could make some progress, but wasn't learning to get past the point where it repeatedly failed. This was the baseline that motivated me to explore Bayesian optimisation and LLM assistance for tuning the weights.

{{< video
  src="/videos/first-attempt.mp4"
  caption="The agent playing Forest Follies with manually chosen reward weights."
>}}

### Weights chosen by LLM

With weights suggested by an LLM, the agent finally completed Forest Follies for the first time. The video below shows that run. It reached the exit with just **1 HP remaining**, but after being hard stuck with my manually chosen weights, seeing it finish was a major milestone.

On average, the agent completed the level in about **1 out of 5 attempts (20%)**. The narrow finish also showed there was still room to improve the balance between progress and preserving health.

{{< video
  src="/videos/second-attempt.mp4"
  caption="The agent's first completion of Forest Follies, using LLM-suggested reward weights, with 1 HP remaining."
>}}

## Conclusion

Getting an agent to complete even one level of Cuphead turned out to be hard. Reward shaping and dense feedback helped make that goal achievable, but finding a useful balance between progress, survival, and combat took experimentation.

I didn't have much success tuning the weights with Bayesian optimisation in these experiments, but it remains an approach worth investigating further. Reaching the exit was a milestone; learning to do it consistently and quickly is the next challenge.

To finish, here's a human speedrun of the same level. The agent has a long way to go!

{{< youtube id="6u1ogr8Szmc" title="Human speedrun of Forest Follies" loading="lazy" >}}

[^mnih2013]: Mnih et al. (2013). *Playing Atari with Deep Reinforcement Learning*. arXiv preprint arXiv:1312.5602. [Read the paper](https://arxiv.org/abs/1312.5602).

[^ng1999]: Ng, A. Y., Harada, D., and Russell, S. (1999). *Policy Invariance Under Reward Transformations: Theory and Application to Reward Shaping*. Proceedings of ICML. [Read the paper](https://ai.stanford.edu/~ang/papers/shaping-icml99.pdf).
