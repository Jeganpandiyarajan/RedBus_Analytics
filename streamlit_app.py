# RedBus Analytics Dashboard - Complete Version (dbt GOLD layer)
# Streamlit App for Bus Booking Analytics

import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

# Page Configuration
st.set_page_config(
    page_title="RedBus Analytics Dashboard",
    page_icon="🚌",
    layout="wide"
)

# Get Snowflake Session
session = get_active_session()

# Title
st.title("RedBus Analytics Dashboard")
st.markdown("---")

st.sidebar.header("Filters")

# Date Range Filter
date_query = """
SELECT DISTINCT JOURNEY_DATE 
FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS 
ORDER BY JOURNEY_DATE
"""
date_df = session.sql(date_query).to_pandas()
min_date = date_df['JOURNEY_DATE'].min()
max_date = date_df['JOURNEY_DATE'].max()

date_range = st.sidebar.date_input(
    "Select Date Range",
    value=(min_date, max_date),
    min_value=min_date,
    max_value=max_date
)

# Route Filter
route_query = """
SELECT DISTINCT ROUTE_DESCRIPTION 
FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS 
ORDER BY ROUTE_DESCRIPTION
"""
route_df = session.sql(route_query).to_pandas()
route_options = ["All"] + route_df['ROUTE_DESCRIPTION'].tolist()
selected_route = st.sidebar.selectbox("Select Route", route_options)

# Operator Filter
operator_query = """
SELECT DISTINCT OPERATOR_NAME 
FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS 
ORDER BY OPERATOR_NAME
"""
operator_df = session.sql(operator_query).to_pandas()
operator_options = ["All"] + operator_df['OPERATOR_NAME'].tolist()
selected_operator = st.sidebar.selectbox("Select Operator", operator_options)

# Bus Type Filter
bus_type_query = """
SELECT DISTINCT BUS_TYPE 
FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS 
ORDER BY BUS_TYPE
"""
bus_type_df = session.sql(bus_type_query).to_pandas()
bus_type_options = ["All"] + bus_type_df['BUS_TYPE'].tolist()
selected_bus_type = st.sidebar.selectbox("Select Bus Type", bus_type_options)

# Customer Segment Filter
segment_query = """
SELECT DISTINCT CUSTOMER_SEGMENT 
FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS 
ORDER BY CUSTOMER_SEGMENT
"""
segment_df = session.sql(segment_query).to_pandas()
segment_options = ["All"] + segment_df['CUSTOMER_SEGMENT'].tolist()
selected_segment = st.sidebar.selectbox("Select Customer Segment", segment_options)

# Payment Mode Filter
payment_query = """
SELECT DISTINCT PAYMENT_MODE 
FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS 
ORDER BY PAYMENT_MODE
"""
payment_df = session.sql(payment_query).to_pandas()
payment_options = ["All"] + payment_df['PAYMENT_MODE'].tolist()
selected_payment = st.sidebar.selectbox("Select Payment Mode", payment_options)

# Booking Status Filter
status_query = """
SELECT DISTINCT BOOKING_STATUS 
FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS 
ORDER BY BOOKING_STATUS
"""
status_df = session.sql(status_query).to_pandas()
status_options = ["All"] + status_df['BOOKING_STATUS'].tolist()
selected_status = st.sidebar.selectbox("Select Booking Status", status_options)

filters = []
filters.append(f"JOURNEY_DATE BETWEEN '{date_range[0]}' AND '{date_range[1]}'")

if selected_route != "All":
    filters.append(f"ROUTE_DESCRIPTION = '{selected_route}'")

if selected_operator != "All":
    filters.append(f"OPERATOR_NAME = '{selected_operator}'")

if selected_bus_type != "All":
    filters.append(f"BUS_TYPE = '{selected_bus_type}'")

if selected_segment != "All":
    filters.append(f"CUSTOMER_SEGMENT = '{selected_segment}'")

if selected_payment != "All":
    filters.append(f"PAYMENT_MODE = '{selected_payment}'")

if selected_status != "All":
    filters.append(f"BOOKING_STATUS = '{selected_status}'")

where_clause = " AND ".join(filters)

main_query = f"""
SELECT 
    BOOKING_ID,
    BOOKING_DATE,
    JOURNEY_DATE,
    CUSTOMER_NAME,
    CUSTOMER_SEGMENT,
    ROUTE_DESCRIPTION,
    SOURCE_CITY,
    DEST_CITY,
    OPERATOR_NAME,
    BUS_TYPE,
    PASSENGER_COUNT,
    FARE_AMOUNT,
    DISCOUNT_PCT,
    NET_AMOUNT,
    BOOKING_STATUS,
    PAYMENT_MODE,
    IS_CANCELLED,
    JOURNEY_YEAR,
    JOURNEY_MONTH,
    JOURNEY_DAY,
    JOURNEY_IS_WEEKEND,
    DISTANCE_KM,
    REGION,
    SEAT_CAPACITY
FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS
WHERE {where_clause}
"""

df = session.sql(main_query).to_pandas()

# If no data, show message
if len(df) == 0:
    st.warning("No data found for the selected filters. Please adjust your filters.")
    st.stop()

st.markdown("## Key Performance Indicators")

col1, col2, col3, col4, col5, col6 = st.columns(6)

with col1:
    total_bookings = len(df)
    st.metric("Total Bookings", f"{total_bookings:,}")

with col2:
    total_revenue = df['NET_AMOUNT'].sum()
    st.metric("Total Revenue", f"₹{total_revenue:,.2f}")

with col3:
    net_revenue = df[df['IS_CANCELLED'] == False]['NET_AMOUNT'].sum()
    st.metric("Net Revenue", f"₹{net_revenue:,.2f}")

with col4:
    avg_fare = df['NET_AMOUNT'].mean()
    st.metric("Avg Fare", f"₹{avg_fare:,.2f}")

with col5:
    cancelled = df[df['IS_CANCELLED'] == True].shape[0]
    cancel_rate = (cancelled / total_bookings * 100) if total_bookings > 0 else 0
    st.metric("Cancellation Rate", f"{cancel_rate:.1f}%")

with col6:
    total_passengers = df['PASSENGER_COUNT'].sum()
    st.metric("Total Passengers", f"{total_passengers:,}")

st.markdown("---")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Revenue Trend")
    revenue_trend = df.groupby('JOURNEY_DATE')['NET_AMOUNT'].sum().reset_index()
    if len(revenue_trend) > 0:
        st.line_chart(revenue_trend.set_index('JOURNEY_DATE'))
    else:
        st.info("No data for revenue trend")

with col2:
    st.subheader("Bookings Trend")
    bookings_trend = df.groupby('JOURNEY_DATE').size().reset_index(name='COUNT')
    if len(bookings_trend) > 0:
        st.bar_chart(bookings_trend.set_index('JOURNEY_DATE'))
    else:
        st.info("No data for bookings trend")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Revenue by Route")
    route_rev = df[df['IS_CANCELLED'] == False].groupby('ROUTE_DESCRIPTION')['NET_AMOUNT'].sum().sort_values(ascending=False).head(10)
    if len(route_rev) > 0:
        st.bar_chart(route_rev)
    else:
        st.info("No data for route revenue")

with col2:
    st.subheader("Revenue by Operator")
    op_rev = df[df['IS_CANCELLED'] == False].groupby('OPERATOR_NAME')['NET_AMOUNT'].sum().sort_values(ascending=False).head(10)
    if len(op_rev) > 0:
        st.bar_chart(op_rev)
    else:
        st.info("No data for operator revenue")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Bookings by Bus Type")
    bus_type_ct = df['BUS_TYPE'].value_counts()
    if len(bus_type_ct) > 0:
        st.bar_chart(bus_type_ct)
    else:
        st.info("No data for bus type")

with col2:
    st.subheader("Weekend vs Weekday Bookings")
    if 'JOURNEY_IS_WEEKEND' in df.columns:
        weekend_ct = df['JOURNEY_IS_WEEKEND'].map({True: "Weekend", False: "Weekday"}).value_counts()
        if len(weekend_ct) > 0:
            st.bar_chart(weekend_ct)
        else:
            st.info("No data for weekend/weekday")
    else:
        st.info("JOURNEY_IS_WEEKEND column not available")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Revenue by Customer Segment")
    seg_rev = df[df['IS_CANCELLED'] == False].groupby('CUSTOMER_SEGMENT')['NET_AMOUNT'].sum()
    if len(seg_rev) > 0:
        st.bar_chart(seg_rev)
    else:
        st.info("No data for customer segment")

with col2:
    st.subheader("Booking Status Breakdown")
    status_ct = df['BOOKING_STATUS'].value_counts()
    if len(status_ct) > 0:
        st.bar_chart(status_ct)
    else:
        st.info("No data for booking status")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Occupancy Percentage by Bus Type")
    try:
        occupancy_data = df.groupby('BUS_TYPE').agg({
            'PASSENGER_COUNT': 'sum',
            'SEAT_CAPACITY': 'mean'
        }).reset_index()
        
        occupancy_data['OCCUPANCY_PCT'] = round(
            100 * occupancy_data['PASSENGER_COUNT'] / (occupancy_data['SEAT_CAPACITY'] * len(df)), 1
        )
        
        if len(occupancy_data) > 0:
            st.bar_chart(occupancy_data.set_index('BUS_TYPE')['OCCUPANCY_PCT'])
        else:
            st.info("No data for occupancy")
    except Exception as e:
        st.info("Occupancy calculation: " + str(e)[:50])

with col2:
    st.subheader("Payment Mode Split")
    pay_ct = df['PAYMENT_MODE'].value_counts()
    if len(pay_ct) > 0:
        st.bar_chart(pay_ct)
    else:
        st.info("No data for payment mode")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Average Discount Percentage by Segment")
    disc_seg = df.groupby('CUSTOMER_SEGMENT')['DISCOUNT_PCT'].mean().round(1)
    if len(disc_seg) > 0:
        st.bar_chart(disc_seg)
    else:
        st.info("No data for discount by segment")

with col2:
    st.subheader("Top 5 Customers by Spend")
    top_cust = df.groupby('CUSTOMER_NAME')['NET_AMOUNT'].sum().sort_values(ascending=False).head(5)
    if len(top_cust) > 0:
        st.bar_chart(top_cust)
    else:
        st.info("No data for top customers")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Revenue per KM by Route")
    try:
        rev_per_km_data = df[df['IS_CANCELLED'] == False].groupby('ROUTE_DESCRIPTION').agg({
            'NET_AMOUNT': 'sum',
            'DISTANCE_KM': 'first'
        }).reset_index()
        
        rev_per_km_data['REVENUE_PER_KM'] = rev_per_km_data.apply(
            lambda x: x['NET_AMOUNT'] / x['DISTANCE_KM'] if x['DISTANCE_KM'] > 0 else 0, axis=1
        )
        rev_per_km = rev_per_km_data.set_index('ROUTE_DESCRIPTION')['REVENUE_PER_KM'].sort_values(ascending=False).head(10)
        
        if len(rev_per_km) > 0:
            st.bar_chart(rev_per_km)
        else:
            st.info("No data for revenue per KM")
    except Exception as e:
        st.info("Revenue per KM calculation: " + str(e)[:50])

with col2:
    st.subheader("Region Performance")
    region_rev = df[df['IS_CANCELLED'] == False].groupby('REGION')['NET_AMOUNT'].sum()
    if len(region_rev) > 0:
        st.bar_chart(region_rev)
    else:
        st.info("No data for region performance")

st.markdown("---")
st.subheader("Ask About RedBus Policies")

# Check if documents exist
doc_count_query = "SELECT COUNT(*) FROM REDBUS_ANALYTICS.DW.DOCS"
doc_count = session.sql(doc_count_query).to_pandas().iloc[0, 0]

if doc_count == 0:
    st.warning("No policy documents found. Please upload documents first.")
else:
    user_question = st.text_area(
        "Ask a question about RedBus policies:",
        placeholder="Example: What is the cancellation fee? How do I get a refund? What are the operator standards?",
        height=80
    )
    
    col1, col2, col3 = st.columns([1, 1, 4])
    with col1:
        search_button = st.button("Search", type="primary", use_container_width=True)
    
    if search_button and user_question:
        with st.spinner("Searching policies..."):
            try:
                keywords = user_question.lower().split()
                
                stop_words = ['what', 'is', 'the', 'a', 'an', 'of', 'for', 'to', 'with', 'on', 'at', 'from', 'by', 'in', 'and', 'or', 'but', 'not', 'are', 'was', 'were', 'has', 'have', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall']
                keywords = [k for k in keywords if k not in stop_words and len(k) > 2]
                
                if len(keywords) == 0:
                    st.info("Please use more specific keywords like 'cancellation', 'refund', or 'operator'.")
                else:
                    search_conditions = " OR ".join([f"LOWER(FILE_CONTENT) LIKE LOWER('%{k}%')" for k in keywords])
                    
                    search_query = f"""
                    SELECT 
                        FILE_NAME,
                        FILE_CONTENT
                    FROM REDBUS_ANALYTICS.DW.DOCS
                    WHERE {search_conditions}
                    """
                    
                    results = session.sql(search_query).to_pandas()
                    
                    if len(results) > 0:
                        st.success(f"Found {len(results)} relevant policy documents!")
                        st.markdown("---")
                        
                        for i, row in results.iterrows():
                            with st.expander(f"File: {row['FILE_NAME']}", expanded=True):
                                st.text(row['FILE_CONTENT'])
                                st.caption(f"Source: {row['FILE_NAME']}")
                    else:
                        st.info("No matching policy documents found. Please try different keywords like 'cancellation', 'refund', or 'operator'.")
                    
            except Exception as e:
                st.error("Error: " + str(e))
                st.info("Tip: Try using simpler keywords like 'cancellation', 'refund', or 'operator'.")
    
    elif search_button and not user_question:
        st.warning("Please enter a question first.")

st.markdown("---")
st.subheader("Booking Data Explorer")

display_cols = [
    'BOOKING_ID', 'JOURNEY_DATE', 'CUSTOMER_NAME', 'CUSTOMER_SEGMENT',
    'ROUTE_DESCRIPTION', 'OPERATOR_NAME', 'BUS_TYPE', 'PAYMENT_MODE',
    'PASSENGER_COUNT', 'NET_AMOUNT', 'BOOKING_STATUS', 'IS_CANCELLED'
]
display_df = df[display_cols].head(100)

st.dataframe(
    display_df,
    use_container_width=True,
    hide_index=True
)

st.markdown("---")
st.caption(f"RedBus Analytics Dashboard | Data refreshed: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')} | Total Records: {len(df):,}")
