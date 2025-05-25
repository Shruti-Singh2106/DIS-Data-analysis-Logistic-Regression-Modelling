# 📊 Retirement Scheme Participation Analysis Using Household Survey Data (Stata)

## 🗂️ Project Overview

This project analyzes factors influencing **retirement scheme participation** among Indian households using Visit 1 data from a detailed household survey. The workflow involves importing raw CSV files, cleaning and transforming the data, creating relevant variables, and running logistic regression models. Several visualizations help interpret the relationships between demographic, financial, and locational factors.

---

## 📁 Repository Structure

```
├── csv files/                      # Raw survey data (CSV)
├── stata for t2/                  # Cleaned and processed Stata (.dta) files
├── final_analysis.do              # Main Stata script for processing and analysis
├── README.md                      # Project overview and documentation
```

---

## 🧾 Data Description

The following levels from the household survey are used:

| File Name | Description |
|----------|-------------|
| Visit1 Level 1 | Identification of sample household and field operations |
| Visit1 Level 2 | Demographic and other particulars of household members |
| Visit1 Level 12 | Financial assets including receivables (retirement and others) |
| Visit1 Level 14 | Loans taken for various purposes including other household expenditure |

---

## 🔧 Data Processing Steps

### 1. 📥 CSV Import and Conversion

Each CSV file is imported into Stata and saved as a `.dta` file:

```stata
import delimited "csv files\Visit1 Level - 01 (...).csv"
save "stata for t2\Visit level 1.dta", replace
clear
```

(Repeated for all files.)

---

### 2. 👤 Extract Household Head Information

From Level 2 data:

- Filter to keep only household heads (`b3q3 == 1`)
- Keep relevant variables: `hhid`, `b3q5` (age), `b3q6` (education), `sector`
- Rename for clarity:
  - `b3q5` → `age_hhhead`
  - `b3q6` → `education_hhhead`

---

### 3. 💰 Identify Pension/Retirement Scheme Participation

From Level 12 data:

- Retirement participation variable (`retirement_participation`) is created:
  - 1 if `b11aq1` is 10 or 11
  - 0 otherwise
- Collapsed at household level (`hhid`) using `collapse (max)`.

---

### 4. 🏦 Process Loan Data

From Level 14 data:

- Keep loans with purpose `b12q10 == 12` (Other Household Expenditure)
- Retain `b12q4` (loan amount), `b12q14` (outstanding amount)
- Collapse at household level (sum values)
- Renamed:
  - `total_borrowed_otherexp`
  - `total_outstanding_otherexp`

---

### 5. 🔗 Merge Datasets

Sequential merges are performed using `hhid`:

1. Level 1 + Household head data
2. + Retirement scheme data
3. + Loan data

---

## 🧮 Variable Transformations

- **Urban/Rural Dummy**:
  ```stata
  gen urban_rural = (sector == 2)
  ```

- **Education Categories**:
  ```stata
  gen education_cat = .
  replace education_cat = 0 if education_hhhead == 1
  replace education_cat = 1 if inlist(education_hhhead, 2, 3, 4)
  replace education_cat = 2 if inlist(education_hhhead, 5, 6, 7, 8)
  replace education_cat = 3 if inlist(education_hhhead, 10, 11, 12)
  ```

- **Log Transformation**:
  ```stata
  gen log_total_outstanding_otherexp = log(total_outstanding_otherexp) if total_outstanding_otherexp > 0
  ```

---

## 📈 Logistic Regression Analysis

### Basic Model

```stata
logit retirement_participation log_total_outstanding_otherexp i.education_cat age_hhhead i.urban_rural
```

### With Odds Ratios

```stata
logit retirement_participation log_total_outstanding_otherexp i.education_cat age_hhhead i.urban_rural, or
```

### Interaction Models

- **Debt × Urban/Rural Interaction**:
  ```stata
  logit retirement_participation c.log_total_outstanding_otherexp##i.urban_rural i.education_cat age_hhhead, vce(robust)
  ```

- **Debt × Age Interaction**:
  ```stata
  logit retirement_participation c.log_total_outstanding_otherexp##c.age_hhhead i.education_cat i.urban_rural, vce(robust)
  ```

---

## 🔬 Regression Discontinuity (Optional Robustness Check)

```stata
gen treat = (log_total_outstanding_otherexp <= 10)
rdrobust retirement_participation log_total_outstanding_otherexp, c(10)
```

(Also repeated for cutoffs 9 and 11.)

---

## 📊 Visualizations

### 1. **Margins Plots**

#### Education

```stata
margins education_cat
marginsplot, title("Effect of Education Level on Retirement Participation") ///
    xlabel(0 "Illiterate" 1 "Primary" 2 "Secondary" 3 "Graduate+")
```

#### Age

```stata
margins, at(age_hhhead=(15(5)80))
marginsplot, title("Effect of Age on Retirement Participation")
```

#### Urban vs Rural

```stata
margins urban_rural
marginsplot, title("Urban vs Rural: Retirement Participation")
```

---

### 2. **Descriptive Graphs**

#### Education Distribution

```stata
label define educlb 0 "Illiterate" 1 "Primary" 2 "Secondary" 3 "Graduate+"
label values education_cat educlb
graph bar (count), over(education_cat) title("Education Level of Household Head")
```

#### Age Histogram

```stata
histogram age_hhhead, bin(20) color(orange) title("Distribution of Household Head Age")
```

#### Urban/Rural Distribution

```stata
graph bar (count), over(urban_rural) title("Urban vs Rural Households")
```

---

### 3. **Retirement Participation Pie Chart**

```stata
label define partlb2 0 "Not Participate" 1 "Participate"
label values retirement_participation partlb2

grstyle init
grstyle set color #ff0000 #00ff00

graph pie, over(retirement_participation) ///
    plabel(_all percent, size(medium)) ///
    title("Retirement Scheme Participation")
```

---

### 4. **Histogram of Log Debt**

```stata
histogram log_total_outstanding_otherexp, normal ///
    title("Distribution of Log-Transformed Consumer Debt") ///
    xlabel(, grid) ylabel(, grid)
```

---

## 📌 Notes

- All analyses assume clean merges with no missing `hhid`s.
- Ensure `rdrobust`, `grstyle`, `palettes`, and `colrspace` are installed using `ssc install`.
- Suitable for use in understanding socio-economic determinants of financial planning behavior.

---

## 📜 License

This project is for academic/research use. Please cite appropriately if used.

---

## 🙋‍♀️ Author

**Shruti Singh**  
Master's Student in Economics  
GitHub: [yourusername]  
Email: [your.email@example.com]
