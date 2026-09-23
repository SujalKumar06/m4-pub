# Part 4A
## Part A

Copilot's reply:

```
Optimized tool selectionI’m checking the specific test and pricing logic that produces this assertion so I can explain the real root cause in plain English without proposing a fix yet.

Searched for regex `quotesDiscountForLoyalCustomer|loyal|tier 3|10% off|5-year` (`**/{src/**,test/**}`), 24 results

Read 

Read 

## What this failure means

This is not a Java crash or NullPointerException. It is a JUnit assertion failure.

The test named `quotesDiscountForLoyalCustomer` in `PriceEngineTest.java` is saying:

- expected final price: 90.0
- actual final price: 95.0

In plain English: for a customer with 5 years of loyalty, the code was supposed to apply the 10% tier-3 discount, but instead it applied only the 5% tier-2 discount.

---

## Why the numbers show that

The order is a simple 100-dollar item with:

- no expedited shipping
- no promo code
- no tax
- customer loyalty years = 5

So the only thing affecting the total is the loyalty discount.

- 10% off of 100 = 90
- 5% off of 100 = 95

The fact that the actual result is 95 tells us the code took the wrong branch in the loyalty calculation.

---

## Most likely root cause

The likely root cause is an off-by-one bug in the loyalty-tier logic inside `PriceEngine.java`.

The code is effectively doing:

- if years > 5 → 10% discount
- else if years >= 3 → 5% discount
- else if years >= 1 → 2% discount

That means a customer with exactly 5 years is not treated as tier 3. They fall into the tier-2 branch because `5 > 5` is false and `5 >= 3` is true.

So the bug is: the boundary condition for the 10% discount is written as `> 5` instead of `>= 5`.

> In other words, the code is checking “more than 5 years” instead of “5 or more years,” which explains why the expected 90.0 became 95.0.
```

I got it using one line of stack trace, Yes I agree with the explaination it gave me because in the comments its written that 
```java
    // 4. Loyalty-tier discount
    //    tier 1 (1-2 years):  2% off
    //    tier 2 (3-4 years):  5% off
    //    tier 3 (5+ years):  10% off
```
so for the code line it said 
```java
if (years > 5)
```
which is wrong because it said 5+ years, so it is correct. I don't need to give the full stack trace everytime.

## Part B

## Part C
Explaination was easier to understand than the actual patch because it was in plain English. 

- We should first give few relevant lines and see if it is able to spot the bug, otherwise keep incrementing and paste the whole stack trace

# Part 4B 

The code's cyclomatic complexity is 23 which I calculated manually 

## A

| Rank | Method | Current cyclomatic complexity estimate | First refactor move | Expected complexity reduction |
|---|---|---:|---|---|
| 1 | `PriceEngine.quote` | ~15 | `extract-method` | Breaking the method into named stages for subtotal, surcharge, promo, loyalty, and tax will cut the branching density and make each decision path easier to follow and test. |

## B

```java
--- a/src/PriceEngine.java
+++ b/src/PriceEngine.java
@@ -6,11 +6,29 @@
  *   2. Add an expedited-shipping surcharge if flagged.
  *   3. Apply a promo-code discount if the code is one of the known codes.
  *   4. Apply a loyalty-tier discount based on customer.loyaltyYears.
- *   5. Add regional tax.
+ *   5. Add regional tax
  *
  */
 public class PriceEngine {
 
+    private static Money applyLoyaltyDiscount(Money running, Money subtotal, Cu
stomer customer) {
+        int years = customer.loyaltyYears();
+        double loyaltyRate;
+        if (years >= 5) {
+            loyaltyRate = 0.10;
+        } else if (years >= 3) {
+            loyaltyRate = 0.05;
+        } else if (years >= 1) {
+            loyaltyRate = 0.02;
+        } else {
+            loyaltyRate = 0.0;
+        }
+        if (loyaltyRate > 0.0) {
+            running = running.subtract(subtotal.times(loyaltyRate));
+        }
+        return running;
+    }
+
     public static Money quote(Order order, Customer customer) {
         if (order == null || order.lines() == null || order.lines().isEmpty()) 
{
             throw new IllegalArgumentException("order has no lines");
@@ -49,23 +67,7 @@ public class PriceEngine {
         }
 
         // 4. Loyalty-tier discount
-        //    tier 1 (1-2 years):  2% off
-        //    tier 2 (3-4 years):  5% off
-        //    tier 3 (5+ years):  10% off
-        int years = customer.loyaltyYears();
-        double loyaltyRate;
-        if (years >= 5) {
-            loyaltyRate = 0.10;
-        } else if (years >= 3) {
-            loyaltyRate = 0.05;
-        } else if (years >= 1) {
-            loyaltyRate = 0.05;
-        } else if (years >= 1) {
-            loyaltyRate = 0.02;
-        } else {
-            loyaltyRate = 0.0;
-        }
-        if (loyaltyRate > 0.0) {
-            running = running.subtract(subtotal.times(loyaltyRate));
-        }
+        running = applyLoyaltyDiscount(running, subtotal, customer);
```

All tests still pass

- pmd says the complexity is 19 now yes it decreased from its original 23.

## D

- Cylomatic Complexity dropped by 4.
- AI suggested to flatten all the clauses but I rejected it doesn't have the a good value for its cleanup with respect to the refactor for quote. Adding it will just add noise and will not chase program's behaviour and not even reduce the risks of bugs.

