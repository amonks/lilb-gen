// Gibberish Generator (JavaScript).
// Algorithm: Letter-based Markov text generator.
// based on work by Keith Enevoldsen, thinkzone.wlonk.com

function generate_input(sample,lev) {
   return sample
}

function generate_gibberish(sample,lev) {
   // Clear output.
   outtext = ""

   // Make the string contain two copies of the input text.
   // This allows for wrapping to the beginning when the end is reached.
   str = sample + " "
   nchars = str.length
   str = str + str


   // Check input length.
   if (nchars < lev) {
   //   alert("Too few input characters.")
      return
   }

   // Pick a random starting character, preferably an uppercase letter.
   for (i = 0; i < 1000; i++) {
      ichar = Math.floor(nchars * Math.random())
      chr = str.charAt(ichar)
      if ((chr >= "A") && (chr <= "Z")) break
   }

   // Write starting characters.
   outtext = outtext + str.substring(ichar, ichar + lev)

   // Set target string.
   target = str.substring(ichar + 1, ichar + lev)

   // Generate characters.
   // Algorithm: Letter-based Markov text generator.
   for (i = 0; i < 500; i++) {
      if (lev == 1) {
         // Pick a random character.
         chr = str.charAt(Math.floor(nchars * Math.random()))
      } else {
         // Find all sets of matching target characters.
         nmatches = 0
         j = -1
         while (true) {
            j = str.indexOf(target, j + 1)
            if ((j < 0) || (j >= nchars)) {
               break
            } else {
               nmatches++
            }
         }

         // Pick a match at random.
         imatch = Math.floor(nmatches * Math.random())

         // Find the character following the matching characters.
         nmatches = 0
         j = -1
         while (true) {
            j = str.indexOf(target, j + 1)
            if ((j < 0) || (j >= nchars)) {
               break
            } else if (imatch == nmatches) {
               chr = str.charAt(j + lev - 1)
               break
            } else {
               nmatches++
            }
         }
      }

      // Output the character.
      outtext = outtext + chr

      // Update the target.
      if (lev > 1) {
         target = target.substring(1, lev - 1) + chr
      }
   }
   return outtext
}
