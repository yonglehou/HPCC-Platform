/*##############################################################################

    HPCC SYSTEMS software Copyright (C) 2015 HPCC Systems.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
############################################################################## */

//fail
//NOTE: This example shouldn't really fail, it illustates a problem converting
//IF(c, ds, ds(f1)) to ds(c OR f1)
//which causes dependencies of f1 to be evaluated when they wouldn't be otherwise.

//This is needed to prevent cntBad being hoisted before the resourcing, and becoming unconditional
//The tests are part of the work aiming to remove this code.
#option ('workunitTemporaries', false);

idRec := { unsigned id; };
mainRec := { unsigned seq, dataset(idRec) ids };

idRec createId(unsigned id) := TRANSFORM
    SELF.id := id;
END; 

mainRec createMain(unsigned c, unsigned num) := TRANSFORM
    SELF.seq := c;
    SELF.ids := DATASET(num, createId(c + (COUNTER-1)));
END;

ds := NOFOLD(DATASET(4, createMain(COUNTER, 3)));

boolean assertTrue(boolean x, const varstring msg = 'Condition should have been true') := BEGINC++
    #option pure
    if (!x)
        rtlFail(0, msg);
    return x;
ENDC++;

trueValue := true : stored('trueValue');
falseValue := false : stored('falseValue');

//Case 1 - a child query where the filter is always correct
cnt := COUNT(ds(assertTrue(seq < 10, 'seq < 10'))) + NOFOLD(100000);
output(ds(seq != cnt));


//Case 2 - a condition that is always false is used from a branch that should never be executed
cntBad := COUNT(ds(assertTrue(seq > 10, 'seq > 10'))) + NOFOLD(100000);

//Problem1: Converting this to a filtered disk read means that cntBad is evaluated always
cond := IF(trueValue, ds, ds(seq != cntBad));
output(cond);

